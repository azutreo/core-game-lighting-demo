Name: "Audio"
RootId: 11475990742535607296
Objects {
  Id: 1420496228620727670
  Name: "Cinematic Music Score Set 01"
  Transform {
    Location {
    }
    Rotation {
    }
    Scale {
      X: 1
      Y: 1
      Z: 1
    }
  }
  ParentId: 11475990742535607296
  UnregisteredParameters {
    Overrides {
      Name: "bp:Type"
      Enum {
        Value: "mc:emx_cinematicmusic:38"
      }
    }
    Overrides {
      Name: "bp:Continue Play While Silent"
      Bool: true
    }
  }
  Collidable_v2 {
    Value: "mc:ecollisionsetting:inheritfromparent"
  }
  Visible_v2 {
    Value: "mc:evisibilitysetting:inheritfromparent"
  }
  Blueprint {
    BlueprintAsset {
      Id: 12886117569076347917
    }
    TeamSettings {
    }
    AudioBP {
      AutoPlay: true
      Repeat: true
      Volume: 0.25
      Falloff: 3600
      Radius: 400
    }
  }
}
