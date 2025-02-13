module subprocess;

/*
    Writes to stdout to see if redirecting by parent process works.
*/

import core.runtime;
import std.string;
import std.stdio;
import std.utf;

auto toUTF16z(S)(S s)
{
    return toUTFz!(const(wchar)*)(s);
}

pragma(lib, "gdi32.lib");
pragma(lib, "winmm.lib");

import core.sys.windows.mmsystem;
import core.sys.windows.windef;
import core.sys.windows.winuser;
import core.sys.windows.wingdi;

extern(Windows)
int WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    int result;

    try
    {
        Runtime.initialize();
        result = myWinMain(hInstance, hPrevInstance, lpCmdLine, iCmdShow);
        Runtime.terminate();
    }
    catch(Throwable o)
    {
        MessageBox(null, o.toString().toUTF16z, "Error", MB_OK | MB_ICONEXCLAMATION);
        result = 0;
    }

    return result;
}

int myWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    string appName = "HelloWin";
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
    wndclass.hbrBackground = cast(HBRUSH)GetStockObject(WHITE_BRUSH);
    wndclass.lpszMenuName  = NULL;
    wndclass.lpszClassName = appName.toUTF16z;

    if(!RegisterClass(&wndclass))
    {
        MessageBox(NULL, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    hwnd = CreateWindow(appName.toUTF16z,      // window class name
                         "The Hello Program",  // window caption
                         WS_OVERLAPPEDWINDOW,  // window style
                         500,        // initial x position
                         200,        // initial y position
                         150,        // initial x size
                         100,        // initial y size
                         NULL,                 // parent window handle
                         NULL,                 // window menu handle
                         hInstance,            // program instance handle
                         NULL);                // creation parameters

    ShowWindow(hwnd, iCmdShow);
    UpdateWindow(hwnd);

    while (GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return msg.wParam;
}

extern(Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) nothrow
{
    scope (failure) assert(0);

    HDC hdc;
    PAINTSTRUCT ps;
    RECT rect;
    static int i;
    enum ID_TIMER = 1;

    switch (message)
    {
        case WM_CREATE:
        {
            SetTimer(hwnd, ID_TIMER, 500, NULL);
            return 0;
        }

        case WM_TIMER:
        {
            writefln("Captured string #%s", i++);
            stdout.flush();
            return 0;
        }

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);
            scope(exit) EndPaint(hwnd, &ps);

            GetClientRect(hwnd, &rect);
            DrawText(hdc, "Calling writefln.", -1, &rect, DT_SINGLELINE | DT_CENTER | DT_VCENTER);
            return 0;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
