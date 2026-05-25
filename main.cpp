#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "backend/DataModel.h"
#include "backend/Controller.h"
#include "backend/Simulator.h"
#include "ui/GaugeItem.h"
#include "ui/CANReader.h"   // ← добавлено

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("CarDashboard");
    app.setOrganizationName("AutomotiveUI");

    qmlRegisterType<GaugeItem>("CarDashboard", 1, 0, "GaugeItem");

    QQmlApplicationEngine engine;

    DataModel  dataModel;
    Controller controller;
    Simulator  simulator(&dataModel, &controller);
    CANReader  canReader(&dataModel);             // ← добавлено

    engine.rootContext()->setContextProperty("dataModel",  &dataModel);
    engine.rootContext()->setContextProperty("controller", &controller);
    engine.rootContext()->setContextProperty("simulator",  &simulator);
    engine.rootContext()->setContextProperty("canReader",  &canReader); // ← добавлено

    simulator.start();

    const QUrl url(QStringLiteral("qrc:/ui/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl) QCoreApplication::exit(-1);
                     }, Qt::QueuedConnection);

    engine.load(url);
    return app.exec();
}
