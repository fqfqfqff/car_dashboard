#include <QCoreApplication>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QSGRendererInterface>

#ifdef Q_OS_ANDROID
#include <QJniObject>
#include <QTimer>
#include <QtCore/qcoreapplication_platform.h>
#endif

#include "backend/Controller.h"
#include "backend/DataModel.h"
#include "backend/Simulator.h"
#include "ui/CANReader.h"
#include "ui/GaugeItem.h"

#ifdef Q_OS_ANDROID
static void applyAndroidWindowMode()
{
    QNativeInterface::QAndroidApplication::runOnAndroidMainThread([]() -> QVariant {
        if (!QNativeInterface::QAndroidApplication::isActivityContext())
            return {};

        QJniObject activity = QNativeInterface::QAndroidApplication::context();
        if (!activity.isValid())
            return {};

        QJniObject window = activity.callObjectMethod("getWindow", "()Landroid/view/Window;");
        if (!window.isValid())
            return {};

        constexpr jint keepScreenOnFlag = 128;
        constexpr jint immersiveFlags = 0x1706;

        window.callMethod<void>("addFlags", "(I)V", keepScreenOnFlag);

        QJniObject decorView = window.callObjectMethod("getDecorView", "()Landroid/view/View;");
        if (decorView.isValid())
            decorView.callMethod<void>("setSystemUiVisibility", "(I)V", immersiveFlags);

        return {};
    }).waitForFinished();
}
#endif

int main(int argc, char *argv[])
{
#ifdef Q_OS_ANDROID
    QCoreApplication::setAttribute(Qt::AA_UseOpenGLES);
    qputenv("QSG_RHI_BACKEND", QByteArrayLiteral("opengl"));
#endif

    QGuiApplication app(argc, argv);
    app.setApplicationName("CarDashboard");
    app.setOrganizationName("AutomotiveUI");
    app.setOrganizationDomain("ladagranta.local");

    QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);
    qmlRegisterType<GaugeItem>("CarDashboard", 1, 0, "GaugeItem");

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral("qrc:/"));

    DataModel dataModel;
    Controller controller;
    Simulator simulator(&dataModel, &controller);
    CANReader canReader(&dataModel);

    engine.rootContext()->setContextProperty("dataModel", &dataModel);
    engine.rootContext()->setContextProperty("controller", &controller);
    engine.rootContext()->setContextProperty("simulator", &simulator);
    engine.rootContext()->setContextProperty("canReader", &canReader);

    simulator.start();

    const QUrl url(QStringLiteral("qrc:/ui/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl)
                             QCoreApplication::exit(-1);
                     }, Qt::QueuedConnection);

    engine.load(url);

#ifdef Q_OS_ANDROID
    applyAndroidWindowMode();
    QObject::connect(&app, &QGuiApplication::applicationStateChanged, &app,
                     [](Qt::ApplicationState state) {
                         if (state == Qt::ApplicationActive) {
                             QTimer::singleShot(0, []() { applyAndroidWindowMode(); });
                             QTimer::singleShot(400, []() { applyAndroidWindowMode(); });
                         }
                     });
#endif

    return app.exec();
}
