Name: "Components"
RootId: 13166939408216695751
Objects {
  Id: 2111485092005765605
  Name: "PlayerNameplates (PlayerTitles)"
  Transform {
    Scale {
      X: 1
      Y: 1
      Z: 1
    }
  }
  ParentId: 13166939408216695751
  TemplateInstance {
    ParameterOverrideMap {
      key: 5332119631449535659
      value {
        Overrides {
          Name: "Name"
          String: "PlayerNameplates (PlayerTitles)"
        }
        Overrides {
          Name: "Position"
          Vector {
            Z: 50
          }
        }
        Overrides {
          Name: "Rotation"
          Rotator {
          }
        }
        Overrides {
          Name: "Scale"
          Vector {
            X: 1
            Y: 1
            Z: 1
          }
        }
      }
    }
    TemplateAsset {
      Id: 11055860763022342632
    }
  }
}
Objects {
  Id: 6987899792826024428
  Name: "PlayerList (PlayerTitles)"
  Transform {
    Scale {
      X: 1
      Y: 1
      Z: 1
    }
  }
  ParentId: 13166939408216695751
  TemplateInstance {
    ParameterOverrideMap {
      key: 7621446724159773466
      value {
        Overrides {
          Name: "Name"
          String: "PlayerList (PlayerTitles)"
        }
        Overrides {
          Name: "Position"
          Vector {
            Z: 50
          }
        }
        Overrides {
          Name: "Rotation"
          Rotator {
          }
        }
        Overrides {
          Name: "Scale"
          Vector {
            X: 1
            Y: 1
            Z: 1
          }
        }
      }
    }
    TemplateAsset {
      Id: 8478974383969102799
    }
  }
}
Objects {
  Id: 17595719174612773602
  Name: "KillZone"
  Transform {
    Location {
      Z: -500
    }
    Rotation {
    }
    Scale {
      X: 1000
      Y: 1000
      Z: 0.1
    }
  }
  ParentId: 13166939408216695751
  ChildIds: 12509581645832467677
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
  InstanceHistory {
    SelfId: 17595719174612773602
    SubobjectId: 9464210638659690241
    InstanceId: 6240429853496519730
    TemplateId: 1634827738048127191
    WasRoot: true
  }
}
Objects {
  Id: 12509581645832467677
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
  ParentId: 17595719174612773602
  UnregisteredParameters {
    Overrides {
      Name: "cs:Trigger"
      ObjectReference {
        SelfId: 17595719174612773602
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
  InstanceHistory {
    SelfId: 12509581645832467677
    SubobjectId: 15780008397909082430
    InstanceId: 6240429853496519730
    TemplateId: 1634827738048127191
  }
}
