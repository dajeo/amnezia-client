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

    cacheBuffer: 1024

    clip: true
    interactive: false

    delegate: Item {
        implicitWidth: root.width
        implicitHeight: delegateContent.implicitHeight

        ColumnLayout {
            id: delegateContent

            anchors.fill: parent

            LabelWithButtonType {
                implicitWidth: parent.width

                text: name
                descriptionText: description
                rightImageSource: isInstalled ? "qrc:/images/controls/chevron-right.svg" : "qrc:/images/controls/download.svg"

                clickedFunction: function() {
                    if (isInstalled) {
                        var containerIndex = root.model.mapToSource(index)
                        ContainersModel.setCurrentlyProcessedContainerIndex(containerIndex)

                        if (config[ContainerProps.containerTypeToString(containerIndex)]["isThirdPartyConfig"]) {
                            ProtocolsModel.updateModel(config)
                            PageController.goToPage(PageEnum.PageProtocolRaw)
                            return
                        }

                        switch (containerIndex) {
                        case ContainerEnum.OpenVpn: {
                            OpenVpnConfigModel.updateModel(config)
                            PageController.goToPage(PageEnum.PageProtocolOpenVpnSettings)
                            break
                        }
                        case ContainerEnum.WireGuard: {
                            ProtocolsModel.updateModel(config)
                            PageController.goToPage(PageEnum.PageProtocolRaw)
    //                        WireGuardConfigModel.updateModel(config)
    //                        goToPage(PageEnum.PageProtocolWireGuardSettings)
                            break
                        }
                        case ContainerEnum.Ipsec: {
                            ProtocolsModel.updateModel(config)
                            PageController.goToPage(PageEnum.PageProtocolRaw)
    //                        Ikev2ConfigModel.updateModel(config)
    //                        goToPage(PageEnum.PageProtocolIKev2Settings)
                            break
                        }
                        case ContainerEnum.Sftp: {
                            SftpConfigModel.updateModel(config)
                            PageController.goToPage(PageEnum.PageServiceSftpSettings)
                            break
                        }
                        case ContainerEnum.TorWebSite: {
                            PageController.goToPage(PageEnum.PageServiceTorWebsiteSettings)
                            break
                        }

                        default: {
                            if (serviceType !== ProtocolEnum.Other) { //todo disable settings for dns container
                                ProtocolsModel.updateModel(config)
                                PageController.goToPage(PageEnum.PageSettingsServerProtocol)
                            }
                        }
                        }

                    } else {
                        ContainersModel.setCurrentlyProcessedContainerIndex(root.model.mapToSource(index))
                        InstallController.setShouldCreateServer(false)
                        PageController.goToPage(PageEnum.PageSetupWizardProtocolSettings)
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: false
                }
            }

            DividerType {}
        }
    }
}
