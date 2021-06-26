using System;
using System.Collections;
using System.Diagnostics;

namespace NEnt
{
	class Window
	{
		private const int c_privateClassCount = 16;

		private static int[] s_privateClasses;
		private static Dictionary<int, String> s_classNames;
		private static int s_classIdCounter = 1;

		private Windows.HWnd m_hWnd;
		private int m_winClassIndex;



		// Express constructors

		public this(Windows.HWnd hWnd)
		{
			m_hWnd = hWnd;

			m_winClassIndex = AddClassName(hWnd);
		}

		public static Window CreatePopup()
		{
			int privateIndex = 0;
			int classIndex = s_privateClasses[privateIndex];

			if (classIndex < 0)
			{
				classIndex = RegisterClass(");
			}
		}



		private NEntWin.LResult DefaultProc(Windows.HWnd hWnd, uint32 msg, NEntWin.WParam wParam, NEntWin.LParam lParam)
		{
			return NEntWin.DefWindowProcA(hWnd, msg, wParam, lParam);
		}



		public static this()
		{
			s_classNames = new Dictionary<int, String>();
			s_privateClasses = new int[c_privateClassCount];
			for (int i = 0; i < c_privateClassCount; ++i)
			{
				s_privateClasses[i] = -1;
			}
		}

		public static ~this()
		{
			delete s_classNames;
			delete s_privateClasses;
		}

		public static implicit operator Windows.HWnd(Window w)
		{
			return w.m_hWnd;
		}

		public static int RegisterClass(
			NEntWin.LpCStr lpszClassName = null,
			NEntWin.WindowClassStyle style = 0,
			NEntWin.WndProc wndProc = null,
			int32 cbClsExtra = 0,
			int32 cbWndExtra = 0,
			NEntWin.HInstance? hInstance = null,
			NEntWin.HIcon? hIcon = null,
			NEntWin.HCursor? hCursor = null,
			NEntWin.HBrush? hbrBackground = null,
			NEntWin.LpCStr lpszMenuName = null
			)
		{
			NEntWin.WndClassA wc = .();

			String className = scope:: String();
			if (lpszClassName != null)
			{
				className.Append(lpszClassName);
			}
			else
			{
				className.AppendF("NEntWinClass[{}]", s_classIdCounter);
			}

			s_classNames.Add(s_classIdCounter, className);
			s_classIdCounter++;

			// Init
			wc.style = style;
			wc.cbClsExtra = cbClsExtra;
			wc.cbWndExtra = cbWndExtra;
			wc.hInstance = hInstance ?? NEntWin.GetHInstance();
			wc.hIcon = hIcon ?? NEntWin.LoadIconA(0, (char8*)(void*)0x00007f00);
			wc.hCursor = hCursor ?? NEntWin.LoadCursorA(0, (char8*)(void*)0x00007f00); // Please work
			wc.hBrBackground = hbrBackground ?? NEntWin.GetSysColorBrush(.Window);
			wc.lpszMenuName = lpszMenuName;
			wc.lpszClassName = lpszClassName;

			if (wndProc == null)
			{
				wc.wndProc = =>DefaultWndProc;
			}
			else
			{
				wc.wndProc = wndProc;
			}

			return s_classIdCounter - 1;
		}

		public static Windows.HWnd CreateWindow(
			int classID,
			NEntWin.LpCStr windowName,
			NEntWin.ExWndStyle exStyle,
			NEntWin.WndStyle style,
			int width,
			int height,
			int x = 0x80000000, // CW_USEDEFAULT
			int y = 0x80000000, // CW_USEDEFAULT
			Windows.HWnd? parent = null,
			NEntWin.HMenu? menu = null,
			NEntWin.HInstance? instance = null,
			NEntWin.LpVoid lpParam = null
			)
		{
			Runtime.Assert(s_classNames.ContainsKey(classID), "Tried to create window from non-registered class ID.");

			Windows.HWnd newWindow = NEntWin.CreateWindowExA(
				exStyle,
				s_classNames[classID],
				windowName,
				style,
				x, y,
				width, height,
				parent ?? 0,
				menu ?? 0,
				instance ?? NEntWin.GetHInstance(),
				lpParam
			);

			return newWindow;
		}

		public static int AddClassName(Windows.HWnd hWnd)
		{
			const int maxLen = 32;

			NEntWin.LpCStr buffer = scope char8[maxLen]*;
			int len = NEntWin.GetClassName(hWnd, buffer, maxLen);

			s_classNames.Add(s_classIdCounter, scope:: String(buffer, len));
			s_classIdCounter++;

			return s_classIdCounter - 1;
		}

		private static NEntWin.LResult DefaultWndProc(Windows.HWnd hWnd, uint32 msg, NEntWin.WParam wParam, NEntWin.LParam lParam)
		{
			return NEntWin.DefWindowProcA(hWnd, msg, wParam, lParam);
		}
	}
}
