/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module Emf3;

import core.memory;
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

string appName     = "EMF3";
string description = "Enhanced Metafile Demo #3";
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

    LOGBRUSH lb;
    HDC hdc, hdcEMF;
    HENHMETAFILE hemf;
    PAINTSTRUCT  ps;
    RECT rect;

    switch (message)
    {
        case WM_CREATE:
            hdcEMF = CreateEnhMetaFile(NULL,  "emf3.emf", NULL,
                                       "EMF3\0EMF Demo #3\0");

            SelectObject(hdcEMF, CreateSolidBrush(RGB(0, 0, 255)));

            lb.lbStyle = BS_SOLID;
            lb.lbColor = RGB(255, 0, 0);
            lb.lbHatch = 0;

            SelectObject(hdcEMF,
                         ExtCreatePen(PS_SOLID | PS_GEOMETRIC, 5, &lb, 0, NULL));

            if (GetVersion() & 0x80000000)                  // Windows 98
                Rectangle(hdcEMF, 100, 100, 201, 201);
            else                                            // Windows NT
                Rectangle(hdcEMF, 101, 101, 202, 202);

            MoveToEx(hdcEMF, 100, 100, NULL);
            LineTo(hdcEMF, 200, 200);

            MoveToEx(hdcEMF, 200, 100, NULL);
            LineTo(hdcEMF, 100, 200);

            DeleteObject(SelectObject(hdcEMF, GetStockObject(BLACK_PEN)));
            DeleteObject(SelectObject(hdcEMF, GetStockObject(WHITE_BRUSH)));

            hemf = CloseEnhMetaFile(hdcEMF);

            DeleteEnhMetaFile(hemf);
            return 0;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            GetClientRect(hwnd, &rect);

            rect.left   =     rect.right / 4;
            rect.right  = 3 * rect.right / 4;
            rect.top    =     rect.bottom / 4;
            rect.bottom = 3 * rect.bottom / 4;

            hemf = GetEnhMetaFile("emf3.emf");

            PlayEnhMetaFile(hdc, hemf, &rect);
            DeleteEnhMetaFile(hemf);
            EndPaint(hwnd, &ps);
            return 0;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
