// Dev only: when the main menu has listed the saves, load the test save straight away.
// Based on DJ_Kovrik's "Autoload Latest Save" (Nexus 533), but loads a named save so the test
// always starts from the same clean state. Falls back to the newest save if the target is
// missing. Delete r6/scripts/AODev to turn it off.

// Folder name of the save to load (Saved Games/CD Projekt Red/Cyberpunk 2077/<name>).
public func AODevAutoloadTarget() -> String = "ManualSave-900"

@addField(SingleplayerMenuGameController)
private let m_aoDevAutoloaded: Bool;

@wrapMethod(SingleplayerMenuGameController)
protected cb func OnSavesForLoadReady(saves: array<String>) -> Bool {
  let result: Bool = wrappedMethod(saves);
  if this.m_aoDevAutoloaded || ArraySize(saves) == 0 {
    return result;
  }
  // Only once per game launch: returning to the main menu later shouldn't reload.
  this.m_aoDevAutoloaded = true;
  if AODevAutoloadState.Done() {
    return result;
  }
  AODevAutoloadState.MarkDone();
  let index: Int32 = 0;
  let i: Int32 = 0;
  while i < ArraySize(saves) {
    if StrContains(saves[i], AODevAutoloadTarget()) {
      index = i;
      break;
    }
    i += 1;
  }
  ModLog(n"AODev", "autoload " + saves[index] + " (index " + IntToString(index) + " of " + IntToString(ArraySize(saves)) + ", first: " + saves[0] + ")");
  this.GetSystemRequestsHandler().LoadSavedGame(index);
  return result;
}

// Remembers across menu instances that this launch already autoloaded once.
public class AODevAutoloadState extends ScriptableService {
  private let m_done: Bool;

  public static func Done() -> Bool {
    let state: ref<AODevAutoloadState> = GameInstance.GetScriptableServiceContainer().GetService(n"AODevAutoloadState") as AODevAutoloadState;
    return IsDefined(state) && state.m_done;
  }

  public static func MarkDone() -> Void {
    let state: ref<AODevAutoloadState> = GameInstance.GetScriptableServiceContainer().GetService(n"AODevAutoloadState") as AODevAutoloadState;
    if IsDefined(state) {
      state.m_done = true;
    }
  }
}
