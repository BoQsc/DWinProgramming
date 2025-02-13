/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module FontOut;

import core.memory;
import core.runtime;
import core.thread;
import std.conv;
import std.math;
import std.random;
import std.range;
import std.string;
import std.utf : count, toUTFz;

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

import EZFont;
import resource;

string appName     = "FontOut2";
string description = "FontOut2: Using Path to Outline Font";
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
    hinst = hInstance;
    HACCEL hAccel;
    HWND hwnd;
    MSG  msg;
    WNDCLASS wndclass;

    wndclass.style         = CS_HREDRAW | CS_VREDRAW;
    wndclass.lpfnWndProc   = &WndProc;
    wndclass.cbClsExtra    = 0;
    wndclass.cbWndExtra    = 0;
    wndclass.hInstance     = hInstance;
    wndclass.hIcon         = LoadIcon(NULL, IDI_APPLICATION);
    wndclass.hCursor       = LoadCursor(NULL, IDC_ARROW);
    wndclass.hbrBackground = cast(HBRUSH) GetStockObject(WHITE_BRUSH);
    wndclass.lpszMenuName  = appName.toUTF16z;
    wndclass.lpszClassName = appName.toUTF16z;

    if (!RegisterClass(&wndclass))
    {
        MessageBox(NULL, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    hwnd = CreateWindow(appName.toUTF16z,              // window class name
                        description.toUTF16z,          // window caption
                        WS_OVERLAPPEDWINDOW,           // window style
                        CW_USEDEFAULT,                 // initial x position
                        CW_USEDEFAULT,                 // initial y position
                        CW_USEDEFAULT,                 // initial x size
                        CW_USEDEFAULT,                 // initial y size
                        NULL,                          // parent window handle
                        NULL,                          // window menu handle
                        hInstance,                     // program instance handle
                        NULL);                         // creation parameters

    ShowWindow(hwnd, iCmdShow);
    UpdateWindow(hwnd);

    while (GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return msg.wParam;
}

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) nothrow
{
    scope (failure) assert(0);

    static DOCINFO di = DOCINFO(DOCINFO.sizeof,  "Font Demo: Printing");
    static int cxClient, cyClient;
    static PRINTDLG pd = PRINTDLG(PRINTDLG.sizeof);
    BOOL fSuccess;
    HDC  hdc, hdcPrn;
    int  cxPage, cyPage;
    PAINTSTRUCT ps;

    switch (message)
    {
        case WM_COMMAND:

            switch (wParam)
            {
                case IDM_PRINT:

                    // Get printer DC

                    pd.hwndOwner = hwnd;
                    pd.Flags     = PD_RETURNDC | PD_NOPAGENUMS | PD_NOSELECTION;

                    if (!PrintDlg(&pd))
                        return 0;

                    if (NULL == (hdcPrn = pd.hDC))
                    {
                        MessageBox(hwnd,  "Cannot obtain Printer DC",
                                   appName.toUTF16z, MB_ICONEXCLAMATION | MB_OK);
                        return 0;
                    }

                    // Get size of printable area of page

                    cxPage = GetDeviceCaps(hdcPrn, HORZRES);
                    cyPage = GetDeviceCaps(hdcPrn, VERTRES);

                    fSuccess = FALSE;

                    // Do the printer page

                    SetCursor(LoadCursor(NULL, IDC_WAIT));
                    ShowCursor(TRUE);

                    if ((StartDoc(hdcPrn, &di) > 0) && (StartPage(hdcPrn) > 0))
                    {
                        PaintRoutine(hwnd, hdcPrn, cxPage, cyPage);

                        if (EndPage(hdcPrn) > 0)
                        {
                            fSuccess = TRUE;
                            EndDoc(hdcPrn);
                        }
                    }

                    DeleteDC(hdcPrn);

                    ShowCursor(FALSE);
                    SetCursor(LoadCursor(NULL, IDC_ARROW));

                    if (!fSuccess)
                        MessageBox(hwnd,
                                   "Error encountered during printing",
                                   appName.toUTF16z, MB_ICONEXCLAMATION | MB_OK);

                    return 0;

                case IDM_ABOUT:
                    MessageBox(hwnd,  "Font Demonstration Program\n(c) Charles Petzold, 1998",
                               appName.toUTF16z, MB_ICONINFORMATION | MB_OK);
                    return 0;

                default:
            }

            break;

        case WM_SIZE:
            cxClient = LOWORD(lParam);
            cyClient = HIWORD(lParam);
            return 0;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            PaintRoutine(hwnd, hdc, cxClient, cyClient);

            EndPaint(hwnd, &ps);
            return 0;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

void PaintRoutine(HWND hwnd, HDC hdc, int cxArea, int cyArea)
{
    static string szString = "Outline";
    HFONT hFont;
    LOGBRUSH lb;
    SIZE size;

    hFont = EzCreateFont(hdc, "Times New Roman", 1440, 0, 0, TRUE);

    SelectObject(hdc, hFont);
    SetBkMode(hdc, TRANSPARENT);

    GetTextExtentPoint32(hdc, szString.toUTF16z, szString.count, &size);

    BeginPath(hdc);
    TextOut(hdc, (cxArea - size.cx) / 2, (cyArea - size.cy) / 2,
            szString.toUTF16z, szString.count);
    EndPath(hdc);

    lb.lbStyle = BS_SOLID;
    lb.lbColor = RGB(255, 0, 0);
    lb.lbHatch = 0;

    SelectObject(hdc, ExtCreatePen(PS_GEOMETRIC | PS_DOT,
                                   GetDeviceCaps(hdc, LOGPIXELSX) / 24,
                                   &lb, 0, NULL));
    StrokePath(hdc);

    DeleteObject(SelectObject(hdc, GetStockObject(BLACK_PEN)));
    SelectObject(hdc, GetStockObject(SYSTEM_FONT));
    DeleteObject(hFont);
}
