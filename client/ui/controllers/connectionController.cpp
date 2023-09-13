#include "connectionController.h"

#if defined(Q_OS_ANDROID) || defined(Q_OS_IOS)
    #include <QGuiApplication>
#else
    #include <QApplication>
#endif

#include "core/errorstrings.h"

ConnectionController::ConnectionController(const QSharedPointer<ServersModel> &serversModel,
                                           const QSharedPointer<ContainersModel> &containersModel,
                                           const QSharedPointer<VpnConnection> &vpnConnection, QObject *parent)
    : QObject(parent), m_serversModel(serversModel), m_containersModel(containersModel), m_vpnConnection(vpnConnection)
{
    connect(m_vpnConnection.get(), &VpnConnection::connectionStateChanged, this,
            &ConnectionController::onConnectionStateChanged);
    connect(this, &ConnectionController::connectToVpn, m_vpnConnection.get(), &VpnConnection::connectToVpn,
            Qt::QueuedConnection);
    connect(this, &ConnectionController::disconnectFromVpn, m_vpnConnection.get(), &VpnConnection::disconnectFromVpn,
            Qt::QueuedConnection);
}

ConnectionController::~ConnectionController()
{
// todo use ConnectionController instead of using m_vpnConnection directly
#ifdef AMNEZIA_DESKTOP
    if (m_vpnConnection->connectionState() != Vpn::ConnectionState::Disconnected) {
        m_vpnConnection->disconnectFromVpn();
        for (int i = 0; i < 50; i++) {
            qApp->processEvents(QEventLoop::ExcludeUserInputEvents);
            QThread::msleep(100);
            if (m_vpnConnection->isDisconnected()) {
                break;
            }
        }
    }
#endif
}

void ConnectionController::openConnection()
{
    int serverIndex = m_serversModel->getDefaultServerIndex();
    ServerCredentials credentials =
            qvariant_cast<ServerCredentials>(m_serversModel->data(serverIndex, ServersModel::Roles::CredentialsRole));

    DockerContainer container = m_containersModel->getDefaultContainer();
    QModelIndex containerModelIndex = m_containersModel->index(container);
    const QJsonObject &containerConfig =
            qvariant_cast<QJsonObject>(m_containersModel->data(containerModelIndex, ContainersModel::Roles::ConfigRole));

    if (container == DockerContainer::None) {
        emit connectionErrorOccurred(tr("VPN Protocols is not installed.\n Please install VPN container at first"));
        return;
    }

    qApp->processEvents();
    emit connectToVpn(serverIndex, credentials, container, containerConfig);
}

void ConnectionController::closeConnection()
{
    emit disconnectFromVpn();
}

QString ConnectionController::getLastConnectionError()
{
    return errorString(m_vpnConnection->lastError());
}

void ConnectionController::onConnectionStateChanged(Vpn::ConnectionState state)
{
    m_isConnected = false;
    m_connectionStateText = tr("Connection...");
    switch (state) {
    case Vpn::ConnectionState::Connected: {
        m_isConnectionInProgress = false;
        m_isConnected = true;
        m_connectionStateText = tr("Connected");
        break;
    }
    case Vpn::ConnectionState::Connecting: {
        m_isConnectionInProgress = true;
        break;
    }
    case Vpn::ConnectionState::Reconnecting: {
        m_isConnectionInProgress = true;
        m_connectionStateText = tr("Reconnection...");
        break;
    }
    case Vpn::ConnectionState::Disconnected: {
        m_isConnectionInProgress = false;
        m_connectionStateText = tr("Connect");
        break;
    }
    case Vpn::ConnectionState::Disconnecting: {
        m_isConnectionInProgress = true;
        m_connectionStateText = tr("Disconnection...");
        break;
    }
    case Vpn::ConnectionState::Preparing: {
        m_isConnectionInProgress = true;
        break;
    }
    case Vpn::ConnectionState::Error: {
        m_isConnectionInProgress = false;
        m_connectionStateText = tr("Connect");
        emit connectionErrorOccurred(getLastConnectionError());
        break;
    }
    case Vpn::ConnectionState::Unknown: {
        m_isConnectionInProgress = false;
        m_connectionStateText = tr("Connect");
        emit connectionErrorOccurred(getLastConnectionError());
        break;
    }
    }
    emit connectionStateChanged();
}

void ConnectionController::onCurrentContainerChanged()
{
    if(m_isConnected || m_isConnectionInProgress) {
        emit reconnectWithChangedContainer(tr("Settings updated successfully, Reconnnection..."));
        openConnection();
    }
}

QString ConnectionController::connectionStateText() const
{
    return m_connectionStateText;
}

bool ConnectionController::isConnectionInProgress() const
{
    return m_isConnectionInProgress;
}

bool ConnectionController::isConnected() const
{
    return m_isConnected;
}
