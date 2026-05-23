import QtQuick 2.15

Item {
    id: root

    readonly property var activeCriticalLabels: {
        var list = []
        if (typeof dataModel !== "undefined") {
            if (dataModel.oilPressure)          list.push("ДАВЛЕНИЕ МАСЛА")
            if (dataModel.overheating)          list.push("ПЕРЕГРЕВ ДВС")
            if (dataModel.brakeSystem)          list.push("ТОРМОЗНАЯ СИСТЕМА")
            if (dataModel.batteryFault)         list.push("АККУМУЛЯТОР")
            if (dataModel.airbagFault)          list.push("ПОДУШКИ БЕЗОПАСНОСТИ")
            if (dataModel.seatbelt)             list.push("ПРИСТЕГНИТЕ РЕМЕНЬ")
            if (dataModel.brakeFluid)           list.push("ТОРМОЗНАЯ ЖИДКОСТЬ")
            if (dataModel.transmissionFault)    list.push("НЕИСПРАВНОСТЬ АКПП")
            if (dataModel.transmissionOverheat) list.push("ПЕРЕГРЕВ АКПП")
        }
        return list
    }

    readonly property bool anyCritical: activeCriticalLabels.length > 0
}
