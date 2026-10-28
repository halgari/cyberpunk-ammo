// AmmoOverhaul native plugin: per-weapon ammo type.
//
// A spawned weapon (gameweaponObject) keeps its live ammo type as a TweakDBID inside the object;
// the engine copies it from the weapon record's `ammo` flat at spawn and from then on reloads
// from and consumes that ammo. Writing a different ID there gives that one gun a different ammo
// type, without touching the record (measured on 2.50: field at +0x2e4).
//
// The field isn't in the RTTI, so its offset is found at runtime instead of hard-coded: scripts
// look for the record's ammo ID in a freshly spawned gun (AO_FindAmmoFields), confirm a candidate
// by writing and checking the engine's ammo total, and then use it. Writes only happen when the
// field holds the value the caller expects, so a wrong offset after a game patch fails instead of
// corrupting memory.
//
//   AO_FindAmmoFields(weapon, ammo) -> array<Int32>   offsets holding `ammo`
//   AO_ReadAmmoField(weapon, offset) -> TweakDBID
//   AO_WriteAmmoField(weapon, offset, expected, ammo) -> Bool
//   AO_ReadInt32(weapon, offset) -> Int32              (-1 if unreadable)
//   AO_WriteInt32(weapon, offset, expected, value) -> Bool
// The Int32 pair is for the magazine count, which follows the ammo field (+0x10 on 2.50).

#include <RED4ext/RED4ext.hpp>

#include <Windows.h>

namespace
{
// Only the name hash and length identify a TweakDBID; the remaining bytes are a lookup offset
// that may differ between copies of the same ID.
constexpr uint64_t IdMask = 0x000000FFFFFFFFFFull;

// gameweaponObject is 0x540 bytes in 2.50; search a little past it in case it grows.
constexpr int32_t SearchStart = 0x40;
constexpr int32_t SearchEnd = 0x700;

bool Accessible(const void* aPtr, size_t aSize, bool aWrite)
{
    MEMORY_BASIC_INFORMATION mbi{};
    if (!VirtualQuery(aPtr, &mbi, sizeof(mbi)) || mbi.State != MEM_COMMIT)
        return false;
    if (mbi.Protect & (PAGE_GUARD | PAGE_NOACCESS))
        return false;
    const DWORD writable = PAGE_READWRITE | PAGE_EXECUTE_READWRITE | PAGE_WRITECOPY | PAGE_EXECUTE_WRITECOPY;
    if (aWrite && !(mbi.Protect & writable))
        return false;
    auto end = reinterpret_cast<uintptr_t>(mbi.BaseAddress) + mbi.RegionSize;
    return reinterpret_cast<uintptr_t>(aPtr) + aSize <= end;
}

template<typename T>
T* FieldOf(RED4ext::IScriptable* aWeapon, int32_t aOffset, bool aWrite)
{
    if (!aWeapon || aOffset < SearchStart || aOffset + static_cast<int32_t>(sizeof(T)) > SearchEnd)
        return nullptr;
    auto ptr = reinterpret_cast<uint8_t*>(aWeapon) + aOffset;
    return Accessible(ptr, sizeof(T), aWrite) ? reinterpret_cast<T*>(ptr) : nullptr;
}

uint64_t* Field(RED4ext::IScriptable* aWeapon, int32_t aOffset, bool aWrite)
{
    return FieldOf<uint64_t>(aWeapon, aOffset, aWrite);
}

bool SameId(uint64_t aValue, RED4ext::TweakDBID aId)
{
    return (aValue & IdMask) == (aId.value & IdMask);
}

void FindAmmoFields(RED4ext::IScriptable*, RED4ext::CStackFrame* aFrame, RED4ext::DynArray<int32_t>* aOut, int64_t)
{
    RED4ext::Handle<RED4ext::IScriptable> weapon;
    RED4ext::TweakDBID ammo;
    RED4ext::GetParameter(aFrame, &weapon);
    RED4ext::GetParameter(aFrame, &ammo);
    aFrame->code++;
    if (!aOut)
        return;
    for (int32_t off = SearchStart; off + 8 <= SearchEnd; off += 4)
    {
        auto field = Field(weapon.GetPtr(), off, false);
        if (!field)
            break;
        if (SameId(*field, ammo))
            aOut->PushBack(off);
    }
}

void ReadAmmoField(RED4ext::IScriptable*, RED4ext::CStackFrame* aFrame, RED4ext::TweakDBID* aOut, int64_t)
{
    RED4ext::Handle<RED4ext::IScriptable> weapon;
    int32_t offset = 0;
    RED4ext::GetParameter(aFrame, &weapon);
    RED4ext::GetParameter(aFrame, &offset);
    aFrame->code++;
    auto field = Field(weapon.GetPtr(), offset, false);
    if (aOut)
        *aOut = field ? RED4ext::TweakDBID(*field & IdMask) : RED4ext::TweakDBID();
}

void WriteAmmoField(RED4ext::IScriptable*, RED4ext::CStackFrame* aFrame, bool* aOut, int64_t)
{
    RED4ext::Handle<RED4ext::IScriptable> weapon;
    int32_t offset = 0;
    RED4ext::TweakDBID expected;
    RED4ext::TweakDBID ammo;
    RED4ext::GetParameter(aFrame, &weapon);
    RED4ext::GetParameter(aFrame, &offset);
    RED4ext::GetParameter(aFrame, &expected);
    RED4ext::GetParameter(aFrame, &ammo);
    aFrame->code++;
    bool ok = false;
    auto field = Field(weapon.GetPtr(), offset, true);
    if (field && SameId(*field, expected))
    {
        // Keep whatever the bytes above the ID hold.
        *field = (*field & ~IdMask) | (ammo.value & IdMask);
        ok = true;
    }
    if (aOut)
        *aOut = ok;
}

void ReadInt32(RED4ext::IScriptable*, RED4ext::CStackFrame* aFrame, int32_t* aOut, int64_t)
{
    RED4ext::Handle<RED4ext::IScriptable> weapon;
    int32_t offset = 0;
    RED4ext::GetParameter(aFrame, &weapon);
    RED4ext::GetParameter(aFrame, &offset);
    aFrame->code++;
    auto field = FieldOf<int32_t>(weapon.GetPtr(), offset, false);
    if (aOut)
        *aOut = field ? *field : -1;
}

void WriteInt32(RED4ext::IScriptable*, RED4ext::CStackFrame* aFrame, bool* aOut, int64_t)
{
    RED4ext::Handle<RED4ext::IScriptable> weapon;
    int32_t offset = 0;
    int32_t expected = 0;
    int32_t value = 0;
    RED4ext::GetParameter(aFrame, &weapon);
    RED4ext::GetParameter(aFrame, &offset);
    RED4ext::GetParameter(aFrame, &expected);
    RED4ext::GetParameter(aFrame, &value);
    aFrame->code++;
    bool ok = false;
    auto field = FieldOf<int32_t>(weapon.GetPtr(), offset, true);
    if (field && *field == expected)
    {
        *field = value;
        ok = true;
    }
    if (aOut)
        *aOut = ok;
}

void PostRegisterTypes()
{
    auto rtti = RED4ext::CRTTISystem::Get();
    RED4ext::CBaseFunction::Flags flags = {.isNative = true, .isStatic = true};

    auto find = RED4ext::CGlobalFunction::Create("AO_FindAmmoFields", "AO_FindAmmoFields", &FindAmmoFields);
    find->flags = flags;
    find->SetReturnType("array:Int32");
    find->AddParam("handle:gameweaponObject", "weapon");
    find->AddParam("TweakDBID", "ammo");
    rtti->RegisterFunction(find);

    auto read = RED4ext::CGlobalFunction::Create("AO_ReadAmmoField", "AO_ReadAmmoField", &ReadAmmoField);
    read->flags = flags;
    read->SetReturnType("TweakDBID");
    read->AddParam("handle:gameweaponObject", "weapon");
    read->AddParam("Int32", "offset");
    rtti->RegisterFunction(read);

    auto write = RED4ext::CGlobalFunction::Create("AO_WriteAmmoField", "AO_WriteAmmoField", &WriteAmmoField);
    write->flags = flags;
    write->SetReturnType("Bool");
    write->AddParam("handle:gameweaponObject", "weapon");
    write->AddParam("Int32", "offset");
    write->AddParam("TweakDBID", "expected");
    write->AddParam("TweakDBID", "ammo");
    rtti->RegisterFunction(write);

    auto readInt = RED4ext::CGlobalFunction::Create("AO_ReadInt32", "AO_ReadInt32", &ReadInt32);
    readInt->flags = flags;
    readInt->SetReturnType("Int32");
    readInt->AddParam("handle:gameweaponObject", "weapon");
    readInt->AddParam("Int32", "offset");
    rtti->RegisterFunction(readInt);

    auto writeInt = RED4ext::CGlobalFunction::Create("AO_WriteInt32", "AO_WriteInt32", &WriteInt32);
    writeInt->flags = flags;
    writeInt->SetReturnType("Bool");
    writeInt->AddParam("handle:gameweaponObject", "weapon");
    writeInt->AddParam("Int32", "offset");
    writeInt->AddParam("Int32", "expected");
    writeInt->AddParam("Int32", "value");
    rtti->RegisterFunction(writeInt);
}

void RegisterTypes()
{
}
} // namespace

RED4EXT_C_EXPORT bool RED4EXT_CALL Main(RED4ext::v1::PluginHandle, RED4ext::v1::EMainReason aReason,
                                        const RED4ext::v1::Sdk*)
{
    if (aReason == RED4ext::v1::EMainReason::Load)
    {
        auto rtti = RED4ext::CRTTISystem::Get();
        rtti->AddRegisterCallback(RegisterTypes);
        rtti->AddPostRegisterCallback(PostRegisterTypes);
    }
    return true;
}

RED4EXT_C_EXPORT void RED4EXT_CALL Query(RED4ext::v1::PluginInfo* aInfo)
{
    aInfo->name = L"AmmoOverhaul";
    aInfo->author = L"AmmoOverhaul";
    aInfo->version = RED4EXT_V1_SEMVER(0, 2, 0);
    aInfo->runtime = RED4EXT_V1_RUNTIME_VERSION_LATEST;
    aInfo->sdk = RED4EXT_V1_SDK_VERSION_CURRENT;
}

RED4EXT_C_EXPORT uint32_t RED4EXT_CALL Supports()
{
    return RED4EXT_API_VERSION_1;
}
