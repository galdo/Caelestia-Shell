import QtQuick

QtObject {
    // text hat einen Default (statt 'required'): dynamisch erzeugte MenuItems (Variants/
    // createObject) werfen sonst beim Init "Required property text was not initialized"
    // (activeText/activeIcon referenzieren text/icon bevor sie gesetzt sind) -> Log-Flut.
    property string text: ""
    property string icon
    property string trailingIcon
    property string activeIcon: icon
    property string activeText: text

    signal clicked
}
