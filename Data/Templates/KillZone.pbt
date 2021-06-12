Assets {
  Id: 1634827738048127191
  Name: "KillZone"
  PlatformAssetType: 5
  TemplateAsset {
    ObjectBlock {
      RootId: 9464210638659690241
      Objects {
        Id: 9464210638659690241
        Name: "KillZone"
        Transform {
          Scale {
            X: 10
            Y: 10
            Z: 10
          }
        }
        ParentId: 13166939408216695751
        ChildIds: 15780008397909082430
        Collidable_v2 {
          Value: "mc:ecollisionsetting:inheritfromparent"
        }
        Visible_v2 {
          Value: "mc:evisibilitysetting:inheritfromparent"
        }
        Trigger {
          TeamSettings {
            IsTeamCollisionEnabled: true
            IsEnemyCollisionEnabled: true
          }
          TriggerShape_v2 {
            Value: "mc:etriggershape:box"
          }
        }
      }
      Objects {
        Id: 15780008397909082430
        Name: "KillZone"
        Transform {
          Location {
            Z: 500
          }
          Rotation {
          }
          Scale {
            X: 0.000999999931
            Y: 0.000999999931
            Z: 1
          }
        }
        ParentId: 9464210638659690241
        UnregisteredParameters {
          Overrides {
            Name: "cs:Trigger"
            ObjectReference {
              SubObjectId: 9464210638659690241
            }
          }
        }
        Collidable_v2 {
          Value: "mc:ecollisionsetting:inheritfromparent"
        }
        Visible_v2 {
          Value: "mc:evisibilitysetting:inheritfromparent"
        }
        Script {
          ScriptAsset {
            Id: 5321318700814843422
          }
        }
      }
    }
    PrimaryAssetId {
      AssetType: "None"
      AssetId: "None"
    }
  }
  SerializationVersion: 68
}
