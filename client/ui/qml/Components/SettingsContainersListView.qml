import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import SortFilterProxyModel 0.2

import PageEnum 1.0
import ProtocolEnum 1.0
import ContainerEnum 1.0
import ContainerProps 1.0

import "../Controls2"
import "../Controls2/TextTypes"


ListView {
    id: root

    width: parent.width
    height: root.contentItem.height

    clip: true
    interactive: false

    ButtonGroup {
        id: containersRadioButtonGroup
    }

    delegate: Item {
        implicitWidth: root.width
        implicitHeight: containerRadioButton.implicitHeight

        RadioButton {
            id: containerRadioButton

            implicitWidth: parent.width
            implicitHeight: containerRadioButtonContent.implicitHeight

            hoverEnabled: true

            ButtonGroup.group: containersRadioButtonGroup

            indicator: Rectangle {
                anchors.fill: parent
                color: containerRadioButton.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                Behavior on color {
                    PropertyAnimation { duration: 200 }
                }
            }

            checkable: isInstalled

            RowLayout {
                id: containerRadioButtonContent
                anchors.fill: parent

                anchors.rightMargin: 16
                anchors.leftMargin: 16

                z: 1

                ColumnLayout {
                    Layout.topMargin: 20
                    Layout.bottomMargin: 20

                    ListItemTitleType {
                        Layout.fillWidth: true

                        text: name
                    }

                    CaptionTextType {
                        Layout.fillWidth: true

                        text: description
                        color: "#878B91"
                    }
                }

                Image {
                    source: isInstalled ? "qrc:/images/controls/chevron-right.svg" : "qrc:/images/controls/download.svg"

                    width: 24
                    height: 24

                    Layout.rightMargin: 8
                }
            }

            onClicked: {
                if (isInstalled) {
                    var containerIndex = root.model.mapToSource(index)
                    ContainersModel.setCurrentlyProcessedContainerIndex(containerIndex)

                    if (config[ContainerProps.containerTypeToString(containerIndex)]["isThirdPartyConfig"]) {
                        ProtocolsModel.updateModel(config)
                        goToPage(PageEnum.PageProtocolRaw)
                        return
                    }

                    switch (containerIndex) {
                    case ContainerEnum.OpenVpn: {
                        OpenVpnConfigModel.updateModel(config)
                        goToPage(PageEnum.PageProtocolOpenVpnSettings)
                        break
                    }
                    case ContainerEnum.WireGuard: {
                        ProtocolsModel.updateModel(config)
                        goToPage(PageEnum.PageProtocolRaw)
//                        WireGuardConfigModel.updateModel(config)
//                        goToPage(PageEnum.PageProtocolWireGuardSettings)
                        break
                    }
                    case ContainerEnum.Ipsec: {
                        ProtocolsModel.updateModel(config)
                        goToPage(PageEnum.PageProtocolRaw)
//                        Ikev2ConfigModel.updateModel(config)
//                        goToPage(PageEnum.PageProtocolIKev2Settings)
                        break
                    }
                    case ContainerEnum.Sftp: {
                        SftpConfigModel.updateModel(config)
                        goToPage(PageEnum.PageServiceSftpSettings)
                        break
                    }
                    case ContainerEnum.TorWebSite: {
                        goToPage(PageEnum.PageServiceTorWebsiteSettings)
                        break
                    }

                    default: {
                        if (serviceType !== ProtocolEnum.Other) { //todo disable settings for dns container
                            ProtocolsModel.updateModel(config)
                            goToPage(PageEnum.PageSettingsServerProtocol)
                        }
                    }
                    }

                } else {
                    ContainersModel.setCurrentlyProcessedContainerIndex(root.model.mapToSource(index))
                    InstallController.setShouldCreateServer(false)
                    goToPage(PageEnum.PageSetupWizardProtocolSettings)
                }
            }

            MouseArea {
                anchors.fill: containerRadioButton
                cursorShape: Qt.PointingHandCursor
                enabled: false
            }
        }
    }
}