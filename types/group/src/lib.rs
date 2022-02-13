use serde::{Deserialize, Serialize};
use tdn_did::Proof;
use tdn_types::{group::GroupId, primitives::PeerId};

use chat_types::NetworkMessage;

/// Group chat app(service) default TDN GROUP ID.
pub const GROUP_CHAT_ID: GroupId = 2;

/// Group chat Group ID.
pub type GroupChatId = u64;

/// Group chat connect data structure.
/// params: Group Chat ID, join_proof.
#[derive(Serialize, Deserialize)]
pub struct LayerConnect(pub GroupChatId, pub Proof);

/// Group chat connect success result data structure.
/// params: Group ID, group name, group current height.
#[derive(Serialize, Deserialize)]
pub struct LayerResult(pub GroupChatId, pub String, pub i64);

/// ESSE Group chat app's layer Event.
#[derive(Serialize, Deserialize)]
pub enum LayerEvent {
    /// offline. as BaseLayerEvent.
    Offline(GroupChatId),
    /// suspend. as BaseLayerEvent.
    Suspend(GroupChatId),
    /// actived. as BaseLayerEvent.
    Actived(GroupChatId),
    /// online group member. Group ID, member id.
    MemberOnline(GroupChatId, PeerId),
    /// offline group member. Group ID, member id.
    MemberOffline(GroupChatId, PeerId),
    /// sync online members.
    MemberOnlineSync(GroupChatId),
    /// sync online members result.
    MemberOnlineSyncResult(GroupChatId, Vec<PeerId>),
    /// Change the group name.
    GroupName(GroupChatId, String),
    /// close the group chat.
    GroupClose(GroupChatId),
    /// sync group event. Group ID, height, event.
    Sync(GroupChatId, i64, Event),
    /// peer sync event request. Group ID, from.
    SyncReq(GroupChatId, i64),
    /// sync members status.
    /// Group ID, current height, from height, to height,
    /// add members(height, member id, addr, name, avatar),
    /// leaved members(height, member id),
    /// add messages(height, member id, message, time).
    SyncRes(
        GroupChatId,
        i64,
        i64,
        i64,
        Vec<(i64, PeerId, String, Vec<u8>)>,
        Vec<(i64, PeerId)>,
        Vec<(i64, PeerId, NetworkMessage, i64)>,
    ),
}

impl LayerEvent {
    /// get event's group id.
    pub fn gcd(&self) -> &GroupChatId {
        match self {
            Self::Offline(gcd) => gcd,
            Self::Suspend(gcd) => gcd,
            Self::Actived(gcd) => gcd,
            Self::MemberOnline(gcd, ..) => gcd,
            Self::MemberOffline(gcd, ..) => gcd,
            Self::MemberOnlineSync(gcd) => gcd,
            Self::MemberOnlineSyncResult(gcd, ..) => gcd,
            Self::GroupName(gcd, ..) => gcd,
            Self::GroupClose(gcd) => gcd,
            Self::Sync(gcd, ..) => gcd,
            Self::SyncReq(gcd, ..) => gcd,
            Self::SyncRes(gcd, ..) => gcd,
        }
    }
}

/// Group chat event.
#[derive(Serialize, Deserialize, Clone)]
pub enum Event {
    /// params: member id, member name, member avatar.
    MemberJoin(PeerId, String, Vec<u8>),
    /// params: member id,
    MemberLeave(PeerId),
    /// params: member id, message, message time.
    MessageCreate(PeerId, NetworkMessage, i64),
}
