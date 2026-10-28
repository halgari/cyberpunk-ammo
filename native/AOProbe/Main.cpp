// AOProbe: dev-only RED4ext plugin for finding where a spawned weapon keeps its ammo type.
//
// Registers global natives callable from CET (Game.AOProbe_*) and redscript:
//   AOProbe_Find(obj, hash, size, depth) -> String
//       Offsets in the first `size` bytes of obj whose uint32 equals `hash` (the CRC32 part of a
//       TweakDBID). With depth 1, also follows every pointer-looking qword in that range and
//       searches the first 0x800 bytes of what it points to ("+0x318->+0x40").
//   AOProbe_Dump(obj, offset, size) -> String       qwords of obj[offset, offset+size)
//   AOProbe_DumpAt(obj, ptrOffset, offset, size)    same, inside the struct obj+ptrOffset points to
//   AOProbe_Write(obj, offset, value) -> Bool       writes a qword at obj+offset
//   AOProbe_WriteAt(obj, ptrOffset, offset, value)  same, inside the pointed-to struct
// Every read and write first checks the memory is committed and accessible.

#include <RED4ext/RED4ext.hpp>

#include <Windows.h>

#include <cstdio>
#include <string>

namespace
{
bool Accessible(const void* aPtr, size_t aSize, bool aWrite = false)
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

uint8_t* Base(const RED4ext::Handle<RED4ext::IScriptable>& aObj)
{
    return reinterpret_cast<uint8_t*>(aObj.GetPtr());
}

uint8_t* Follow(uint8_t* aBase, int32_t aPtrOffset)
{
    if (!aBase || !Accessible(aBase + aPtrOffset, 8))
        return nullptr;
    auto target = *reinterpret_cast<uint8_t**>(aBase + aPtrOffset);
    return target && Accessible(target, 8) ? target : nullptr;
}

std::string Hex(uint64_t aValue, int aWidth)
{
    char buf[32];
    std::snprintf(buf, sizeof(buf), "%0*llx", aWidth, static_cast<unsigned long long>(aValue));
    return buf;
}

void Search(uint8_t* aBase, int32_t aSize, uint32_t aHash, const std::string& aPrefix, std::string& aOut)
{
    for (int32_t off = 0; off + 4 <= aSize; off += 4)
    {
        if (!Accessible(aBase + off, 4))
            break;
        if (*reinterpret_cast<uint32_t*>(aBase + off) == aHash)
            aOut += aPrefix + "+0x" + Hex(off, 0) + " ";
    }
}

std::string DumpRange(uint8_t* aBase, int32_t aOffset, int32_t aSize)
{
    std::string out;
    for (int32_t off = aOffset; off + 8 <= aOffset + aSize; off += 8)
    {
        if (!Accessible(aBase + off, 8))
        {
            out += "0x" + Hex(off, 3) + ": <inaccessible>\n";
            break;
        }
        out += "0x" + Hex(off, 3) + ": " + Hex(*reinterpret_cast<uint64_t*>(aBase + off), 16) + "\n";
    }
    return out;
}

void Find(RED4ext::IScriptable*, RED4ext::CStackFrame* aFrame, RED4ext::CString* aOut, int64_t)
{
    RED4ext::Handle<RED4ext::IScriptable> obj;
    uint32_t hash = 0;
    int32_t size = 0;
    int32_t depth = 0;
    RED4ext::GetParameter(aFrame, &obj);
    RED4ext::GetParameter(aFrame, &hash);
    RED4ext::GetParameter(aFrame, &size);
    RED4ext::GetParameter(aFrame, &depth);
    aFrame->code++;

    std::string result;
    auto base = Base(obj);
    if (base)
    {
        Search(base, size, hash, "", result);
        if (depth > 0)
        {
            for (int32_t off = 0; off + 8 <= size; off += 8)
            {
                auto target = Follow(base, off);
                if (target && target != base)
                    Search(target, 0x800, hash, "+0x" + Hex(off, 0) + "->", result);
            }
        }
    }
    if (aOut)
        *aOut = RED4ext::CString(result.c_str());
}

void Dump(RED4ext::IScriptable*, RED4ext::CStackFrame* aFrame, RED4ext::CString* aOut, int64_t)
{
    RED4ext::Handle<RED4ext::IScriptable> obj;
    int32_t offset = 0;
    int32_t size = 0;
    RED4ext::GetParameter(aFrame, &obj);
    RED4ext::GetParameter(aFrame, &offset);
    RED4ext::GetParameter(aFrame, &size);
    aFrame->code++;
    auto base = Base(obj);
    if (aOut)
        *aOut = RED4ext::CString(base ? DumpRange(base, offset, size).c_str() : "null");
}

void DumpAt(RED4ext::IScriptable*, RED4ext::CStackFrame* aFrame, RED4ext::CString* aOut, int64_t)
{
    RED4ext::Handle<RED4ext::IScriptable> obj;
    int32_t ptrOffset = 0;
    int32_t offset = 0;
    int32_t size = 0;
    RED4ext::GetParameter(aFrame, &obj);
    RED4ext::GetParameter(aFrame, &ptrOffset);
    RED4ext::GetParameter(aFrame, &offset);
    RED4ext::GetParameter(aFrame, &size);
    aFrame->code++;
    auto target = Follow(Base(obj), ptrOffset);
    if (aOut)
        *aOut = RED4ext::CString(target ? DumpRange(target, offset, size).c_str() : "null");
}

bool WriteQword(uint8_t* aBase, int32_t aOffset, uint64_t aValue)
{
    if (!aBase || !Accessible(aBase + aOffset, 8, true))
        return false;
    *reinterpret_cast<uint64_t*>(aBase + aOffset) = aValue;
    return true;
}

void Write(RED4ext::IScriptable*, RED4ext::CStackFrame* aFrame, bool* aOut, int64_t)
{
    RED4ext::Handle<RED4ext::IScriptable> obj;
    int32_t offset = 0;
    uint64_t value = 0;
    RED4ext::GetParameter(aFrame, &obj);
    RED4ext::GetParameter(aFrame, &offset);
    RED4ext::GetParameter(aFrame, &value);
    aFrame->code++;
    bool ok = WriteQword(Base(obj), offset, value);
    if (aOut)
        *aOut = ok;
}

void WriteAt(RED4ext::IScriptable*, RED4ext::CStackFrame* aFrame, bool* aOut, int64_t)
{
    RED4ext::Handle<RED4ext::IScriptable> obj;
    int32_t ptrOffset = 0;
    int32_t offset = 0;
    uint64_t value = 0;
    RED4ext::GetParameter(aFrame, &obj);
    RED4ext::GetParameter(aFrame, &ptrOffset);
    RED4ext::GetParameter(aFrame, &offset);
    RED4ext::GetParameter(aFrame, &value);
    aFrame->code++;
    bool ok = WriteQword(Follow(Base(obj), ptrOffset), offset, value);
    if (aOut)
        *aOut = ok;
}

template<typename Fn>
RED4ext::CGlobalFunction* Register(const char* aName, Fn aFn, const char* aReturn)
{
    auto func = RED4ext::CGlobalFunction::Create(aName, aName, aFn);
    func->flags = {.isNative = true, .isStatic = true};
    func->SetReturnType(aReturn);
    return func;
}

void PostRegisterTypes()
{
    auto rtti = RED4ext::CRTTISystem::Get();

    auto find = Register("AOProbe_Find", &Find, "String");
    find->AddParam("handle:IScriptable", "obj");
    find->AddParam("Uint32", "hash");
    find->AddParam("Int32", "size");
    find->AddParam("Int32", "depth");
    rtti->RegisterFunction(find);

    auto dump = Register("AOProbe_Dump", &Dump, "String");
    dump->AddParam("handle:IScriptable", "obj");
    dump->AddParam("Int32", "offset");
    dump->AddParam("Int32", "size");
    rtti->RegisterFunction(dump);

    auto dumpAt = Register("AOProbe_DumpAt", &DumpAt, "String");
    dumpAt->AddParam("handle:IScriptable", "obj");
    dumpAt->AddParam("Int32", "ptrOffset");
    dumpAt->AddParam("Int32", "offset");
    dumpAt->AddParam("Int32", "size");
    rtti->RegisterFunction(dumpAt);

    auto write = Register("AOProbe_Write", &Write, "Bool");
    write->AddParam("handle:IScriptable", "obj");
    write->AddParam("Int32", "offset");
    write->AddParam("Uint64", "value");
    rtti->RegisterFunction(write);

    auto writeAt = Register("AOProbe_WriteAt", &WriteAt, "Bool");
    writeAt->AddParam("handle:IScriptable", "obj");
    writeAt->AddParam("Int32", "ptrOffset");
    writeAt->AddParam("Int32", "offset");
    writeAt->AddParam("Uint64", "value");
    rtti->RegisterFunction(writeAt);
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
    aInfo->name = L"AOProbe";
    aInfo->author = L"AmmoOverhaul";
    aInfo->version = RED4EXT_V1_SEMVER(0, 1, 0);
    aInfo->runtime = RED4EXT_V1_RUNTIME_VERSION_LATEST;
    aInfo->sdk = RED4EXT_V1_SDK_VERSION_CURRENT;
}

RED4EXT_C_EXPORT uint32_t RED4EXT_CALL Supports()
{
    return RED4EXT_API_VERSION_1;
}
