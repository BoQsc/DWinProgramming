module drop_source.source;

import std.algorithm;
import std.range;
import std.string;

import core.sys.windows.objidl;
import core.sys.windows.ole2;
import core.sys.windows.winbase;
import core.sys.windows.windef;
import core.sys.windows.winuser;
import core.sys.windows.wtypes;

import utils.com;

class CDropSource : ComObject, IDropSource
{
    extern (Windows)
    override HRESULT QueryInterface(GUID* riid, void** ppv)
    {
        if (*riid == IID_IDropSource)
        {
            *ppv = cast(void*)cast(IUnknown)this;
            AddRef();
            return S_OK;
        }

        return super.QueryInterface(riid, ppv);
    }

    /** Called by OLE whenever Escape/Control/Shift/Mouse buttons have changed. */
    extern (Windows)
    HRESULT QueryContinueDrag(BOOL fEscapePressed, DWORD grfKeyState)
    {
        // if the <Escape> key has been pressed since the last call, cancel the drop
        if (fEscapePressed == TRUE)
            return DRAGDROP_S_CANCEL;

        // if the <LeftMouse> button has been released, then do the drop!
        if ((grfKeyState & MK_LBUTTON) == 0)
            return DRAGDROP_S_DROP;

        // continue with the drag-drop
        return S_OK;
    }

    //	Return either S_OK or DRAGDROP_S_USEDEFAULTCURSORS to instruct OLE to use the
    //  default mouse cursor images
    extern (Windows)
    HRESULT GiveFeedback(DWORD dwEffect)
    {
        return DRAGDROP_S_USEDEFAULTCURSORS;
    }
}
