/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module Colors2;

import core.runtime;
import core.thread;
import std.conv;
import std.math;
import std.range;
import std.string;
import std.utf;

auto toUTF16z(S)(S s)
{
    return toUTFz!(const(wchar)*)(s);
}

pragma(lib, "gdi32.lib");
pragma(lib, "comdlg32.lib");

import core.sys.windows.windef;
import core.sys.windows.winuser;
import core.sys.windows.wingdi;
import core.sys.windows.winbase;
import core.sys.windows.commdlg;

string appName     = "Colors2";
string description = "Color Scroll";
enum ID_TIMER = 1;
HINSTANCE hinst;

extern (Windows)
int WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    int result;

    try
    {
        Runtime.initialize();
        result = myWinMain(hInstance, hPrevInstance, lpCmdLine, iCmdShow);
        Runtime.terminate();
    }
    catch (Throwable o)
    {
        MessageBox(null, o.toString().toUTF16z, "Error", MB_OK | MB_ICONEXCLAMATION);
        result = 0;
    }

    return result;
}

int myWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    static CHOOSECOLOR cc;
    static COLORREF crCustColors[16];

    cc.hwndOwner      = NULL;
    cc.hInstance      = NULL;
    cc.rgbResult      = RGB(0x80, 0x80, 0x80);
    cc.lpCustColors   = crCustColors.ptr;
    cc.Flags          = CC_RGBINIT | CC_FULLOPEN;
    cc.lCustData      = 0;
    cc.lpfnHook       = NULL;
    cc.lpTemplateName = NULL;

    return ChooseColor(&cc);
}
