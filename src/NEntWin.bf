using System;
using System.IO;

namespace NEnt
{
	static class NEntWin
	{
		// Handles

		public typealias HandleType = int32;
		public typealias HMenu = HandleType;
		public typealias HModule = HandleType;
		public typealias HBitmap = HandleType;
		public typealias HInstance = HandleType;
		public typealias HIcon = HandleType;
		public typealias HCursor = HandleType;
		public typealias HBrush = HandleType;

		// Misc

		public typealias WinLong = int32;
		public typealias WinLongLong = int64;
		public typealias WinULong = uint32;
		public typealias WinULongLong = uint64;

		public typealias IntPtr = WinLongLong;
		public typealias LongPtr = WinLongLong;
		public typealias UIntPtr = WinULongLong;
		public typealias ULongPtr = WinULongLong;

		public typealias LpVoid = void*;
		public typealias LpStr = char8*;
		public typealias LpCStr = char8*;
		public typealias LpRect = WinRect*;
		public typealias LpPoint = WinPoint*;
		public typealias LpMSG = WinMSG*;

		public typealias WParam = UIntPtr;
		public typealias LParam = LongPtr;
		public typealias LResult = LongPtr;
		public typealias Word = uint16;
		public typealias DWord = uint32;
		public typealias Atom = Word;

		public function LResult WndProc(Windows.HWnd hWnd, uint32 msg, WParam wParam, LParam lParam);





		// Structs

		[CRepr]
		public struct WinRect
		{
#if SDL2
			public static implicit operator SDL2.SDL.Rect(WinRect r)
			{
				return .(
					(int32)r.left,
					(int32)r.top,
					(int32)(r.right - r.left),
					(int32)(r.bottom - r.top)
				);
			}

			public static implicit operator WinRect(SDL2.SDL.Rect r)
			{
				return .(
					r.x,
					r.y,
					r.x + r.w,
					r.y + r.h
				);
			}
#endif

			public this()
			{
				this = default;
			}

			public this(WinLong left, WinLong top, WinLong right, WinLong bottom)
			{
				this.left = left;
				this.top = top;
				this.right = right;
				this.bottom = bottom;
			}

			public WinLong left;
			public WinLong top;
			public WinLong right;
			public WinLong bottom;
		}

		[CRepr]
		public struct WinPoint
		{
			public this()
			{
				this = default;
			}

			public this(WinLong x, WinLong y)
			{
				this.x = x;
				this.y = y;
			}

			public WinLong x;
			public WinLong y;
		}

		[CRepr]
		public struct WinMSG
		{
			public Windows.HWnd hWnd;
			public uint32		message;
			public WParam 		wParam;
			public LParam		lParam;
			public DWord		time;
			public WinPoint		pt; 
		}

		[CRepr]
		public struct WndClassA
		{
			public WindowClassStyle style;
			public WndProc wndProc;
			public int32 cbClsExtra;
			public int32 cbWndExtra;
			public HInstance hInstance;
			public HIcon hIcon;
			public HCursor hCursor;
			public HBrush hBrBackground;
			public LpCStr lpszMenuName;
			public LpCStr lpszClassName;
		}

		[CRepr]
		public struct MenuItemInfoA
		{
			public struct FMask : uint32
			{
				public const FMask State = 		(.)0x0001;
				public const FMask ID = 		(.)0x0002;
				public const FMask Submenu = 	(.)0x0004;
				public const FMask Checkmarks = (.)0x0008;
				public const FMask Type = 		(.)0x0010;
				public const FMask Data = 		(.)000020;
				public const FMask String = 	(.)0x0040;
				public const FMask Bitmap = 	(.)0x0080;
				public const FMask FType = 		(.)0x0100;
			}

			public struct FType : uint32
			{
				public const FType String =			(.)0x0000;
				public const FType Bitmap =			(.)0x0004;
				public const FType MenuBarBreak =	(.)0x0020;
				public const FType MenuBreak =		(.)0x0040;
				public const FType OwnerDraw =		(.)0x0100;
				public const FType RadioCheck =		(.)0x0200;
				public const FType Separator =		(.)0x0800;
				public const FType RightOrder =		(.)0x2000;
				public const FType RightJustify =	(.)0x4000;
			}

			public struct FState : uint32
			{
				public const FState Enabled = 	(.)0x0000;
				public const FState Unchecked = (.)0x0000;
				public const FState UnHilite = 	(.)0x0000;
				public const FState Grayed = 	(.)0x0003;
				public const FState Disabled = 	(.)0x0003;
				public const FState Checked = 	(.)0x0008;
				public const FState Hilite = 	(.)0x0080;
				public const FState Default = 	(.)0x1000;
			}

			public uint32	cbSize;
			public FMask   	fMask;
			public FType   	fType;
			public FState   fState;
			public uint32   wID;
			public HMenu    hSubMenu;
			public HBitmap  hbmpChecked;
			public HBitmap  hbmpUnchecked;
			public ULongPtr dwItemData;
			public LpStr    dwTypeData;
			public uint32   cch;
			public HBitmap  hbmpItem;
		}

		public struct WndStyle : uint32
		{
			public const WndStyle Tiled = (.)0x00000000;
			public const WndStyle Overlapped = (.)0x00000000;
			public const WndStyle TabStop = (.)0x00010000;
			public const WndStyle Group = (.)0x00020000;
			public const WndStyle SizeBox = (.)0x00040000;
			public const WndStyle ThickFrame = (.)0x00040000;
			public const WndStyle SysMenu = (.)0x00080000;
			public const WndStyle HScroll = (.)0x00100000;
			public const WndStyle VScroll = (.)0x00200000;
			public const WndStyle DLGFrame = (.)0x00400000;
			public const WndStyle Border = (.)0x00800000;
			public const WndStyle Maximize = (.)0x01000000;
			public const WndStyle ClipChildren = (.)0x02000000;
			public const WndStyle ClipSiblings = (.)0x04000000;
			public const WndStyle Disabled = (.)0x08000000;
			public const WndStyle Visible = (.)0x10000000;
			public const WndStyle Iconic = (.)0x20000000;
			public const WndStyle Minimize = (.)0x20000000;
			public const WndStyle Child = (.)0x40000000;
			public const WndStyle Popup = (.)0x80000000;

			public const WndStyle MaximizeBox = (.)0x00010000 | .SysMenu;
			public const WndStyle MinimizeBox = (.)0x00020000 | .SysMenu;
			public const WndStyle Caption = (.)0x00400000 | .Border;

			public const WndStyle PopupWindow = .Popup | .Border | .SysMenu;
			public const WndStyle OverlappedWindow = .Overlapped | .Caption | .SysMenu | .ThickFrame | .MinimizeBox | .MaximizeBox;
			public const WndStyle TiledWindow = OverlappedWindow;


		}

		public struct ExWndStyle : uint32
		{
			public const ExWndStyle LTRReading = 			(.)0x00000000;
			public const ExWndStyle RightScrollbar = 		(.)0x00000000;
			public const ExWndStyle Left = 					(.)0x00000000;
			public const ExWndStyle DLGModalFrame = 		(.)0x00000001;
			public const ExWndStyle NoParentNotify = 		(.)0x00000004;
			public const ExWndStyle TopMost = 				(.)0x00000008;
			public const ExWndStyle AcceptFiles = 			(.)0x00000010;
			public const ExWndStyle Transparent = 			(.)0x00000020;
			public const ExWndStyle MDIChild = 				(.)0x00000040;
			public const ExWndStyle ToolWindow = 			(.)0x00000080;
			public const ExWndStyle WindowEdge = 			(.)0x00000100;
			public const ExWndStyle ClientEdge = 			(.)0x00000200;
			public const ExWndStyle ContextHelp = 			(.)0x00000400;
			public const ExWndStyle Right = 				(.)0x00001000;
			public const ExWndStyle RTLReading = 			(.)0x00002000;
			public const ExWndStyle LeftScrollbar = 		(.)0x00004000;
			public const ExWndStyle ControlParent = 		(.)0x00010000;
			public const ExWndStyle StaticEdge = 			(.)0x00020000;
			public const ExWndStyle AppWindow = 			(.)0x00040000;
			public const ExWndStyle Layered = 				(.)0x00080000;
			public const ExWndStyle NoInherentLayout = 		(.)0x00100000;
			public const ExWndStyle NoRedirectionBitmap = 	(.)0x00200000;
			public const ExWndStyle LayoutRTL = 			(.)0x00400000;
			public const ExWndStyle Composited = 			(.)0x02000000;
			public const ExWndStyle NoActive = 				(.)0x08000000;

			public const ExWndStyle OverlappedWindow = 		.WindowEdge | .ClientEdge;
			public const ExWndStyle PaletteWindow = 		.WindowEdge | .ToolWindow | .TopMost;
		}

		public struct WindowClassStyle : uint32
		{
			public const WindowClassStyle VRedraw = 		(.)0x0001;
			public const WindowClassStyle HRedraw = 		(.)0x0002;
			public const WindowClassStyle DBLCLKS = 		(.)0x0008;
			public const WindowClassStyle OwnDC = 			(.)0x0020;
			public const WindowClassStyle ClassDC = 		(.)0x0040;
			public const WindowClassStyle ParentDC = 		(.)0x0080;
			public const WindowClassStyle NoClose = 		(.)0x0200;
			public const WindowClassStyle SaveBits = 		(.)0x0800;
			public const WindowClassStyle ByteAlignClient = (.)0x1000;
			public const WindowClassStyle ByteAlignWindow = (.)0x2000;
			public const WindowClassStyle GlobalClass = 	(.)0x4000;
			public const WindowClassStyle DropShadow = 		(.)0x00020000;
		}

		public struct AppendMenuFlags : uint32
		{
			public const AppendMenuFlags ByCommand =	(.)0x0000;
			public const AppendMenuFlags ByPosition =	(.)0x0400;

			public const AppendMenuFlags String =		(.)0x0000;
			public const AppendMenuFlags Enabled =		(.)0x0000;
			public const AppendMenuFlags Unchecked =	(.)0x0000;
			public const AppendMenuFlags Grayed =		(.)0x0001;
			public const AppendMenuFlags Disabled =		(.)0x0002;
			public const AppendMenuFlags Bitmap =		(.)0x0004;
			public const AppendMenuFlags Checked =		(.)0x0008;
			public const AppendMenuFlags Popup =		(.)0x0010;
			public const AppendMenuFlags MenuBarBreak =	(.)0x0020;
			public const AppendMenuFlags MenuBreak =	(.)0x0040;
			public const AppendMenuFlags OwnerDraw =	(.)0x0100;
			public const AppendMenuFlags Separator =	(.)0x0800;
		}

		// Unpopulated
		public struct SystemColor : uint32
		{
			public const SystemColor Window = (.)5;
			public const SystemColor Face3D = (.)15;
		}





		// Macro redefinitions

		public static uint32 LoWord(uint32 integer)
		{
			return integer & 0xFFFF;
		}

		public static uint64 LoWord(uint64 integer)
		{
			return integer & 0xFFFF;
		}

		public static uint32 HiWord(uint32 integer)
		{
			return (integer >> 16) & 0xFFFF;
		}

		public static uint64 HiWord(uint64 integer)
		{
			return (integer >> 16) & 0xFFFF;
		}



		// Menu functions

		[Import("User32.lib"), CLink, CallingConvention(.Stdcall)]
		public static extern HMenu CreateMenu();

		[Import("User32.lib"), CLink, CallingConvention(.Stdcall)]
		public static extern Windows.IntBool SetMenu(Windows.HWnd hWnd, HMenu hMenu);

		[Import("User32.lib"), CLink, CallingConvention(.Stdcall)]
		public static extern Windows.IntBool InsertMenuItemA(HMenu hMenu, uint32 item, Windows.IntBool fByPosition, MenuItemInfoA* lpcMenuItemInfo);

		// [Import("User32.lib"), CLink, CallingConvention(.Stdcall)]
		// public static extern Windows.IntBool AppendMenuItemA(HMenu hMenu, uint32 uFlags, uint32* uIDNewItem, LpCStr lpNewItem);

		[Import("User32.lib"), CLink, CallingConvention(.Stdcall)]
		public static extern Windows.IntBool AppendMenuA(HMenu hMenu, AppendMenuFlags uFlags, UIntPtr uIDNewItem, LpCStr lpNewItem);

		[Import("User32.lib"), CLink, CallingConvention(.Stdcall)]
		public static extern Windows.IntBool InsertMenuA(HMenu hMenu, uint32 uPosition, AppendMenuFlags uFlags, UIntPtr uIDNewItem, LpCStr lpNewItem);

		[Import("User32.lib"), CLink, CallingConvention(.Stdcall)]
		public static extern Windows.IntBool DrawMenuBar(Windows.HWnd hWnd);



		[Import("User32.lib"), CLink, CallingConvention(.Stdcall)]
		public static extern Windows.IntBool GetWindowRect(Windows.HWnd hWnd, LpRect lpRect);

		[Import("User32.lib"), CLink, CallingConvention(.Stdcall)]
		public static extern Windows.IntBool GetClientRect(Windows.HWnd hWnd, LpRect lpRect);

		[Import("User32.lib"), CLink, CallingConvention(.Stdcall)]
		public static extern int GetSystemMetrics(int nIndex);

		[Import("User32.lib"), CLink, CallingConvention(.Stdcall)]
		public static extern Windows.IntBool ClientToScreen(Windows.HWnd hWnd, LpPoint lpPoint);

		[Import("User32.lib"), CLink, CallingConvention(.Stdcall)]
		public static extern Windows.IntBool GetMessage(LpMSG lpMsg, Windows.HWnd hWnd, uint32 wMsgFilterMin, uint32 wMsgFilterMax);

		[Import("User32.lib"), CLink, CallingConvention(.Stdcall)]
		public static extern Windows.IntBool TranslateMessage(LpMSG lpMsg);

		[Import("User32.lib"), CLink, CallingConvention(.Stdcall)]
		public static extern LResult DispatchMessage(LpMSG lpMsg);

		[Import("User32.lib"), CLink, CallingConvention(.Stdcall)]
		public static extern HModule GetModuleHandleA(LpCStr lpModuleName);

		[Import("User32.lib"), CLink, CallingConvention(.Stdcall)]
		public static extern HBrush GetSysColorBrush(SystemColor index);

		[Import("User32.lib"), CLink, CallingConvention(.Stdcall)]
		public static extern HCursor LoadCursorA(HInstance hInstance, LpCStr lpCursorName);

		[Import("User32.lib"), CLink, CallingConvention(.Stdcall)]
		public static extern HIcon LoadIconA(HInstance hInstance, LpCStr lpIconName);
		
		[Import("User32.lib"), CLink, CallingConvention(.Stdcall)]
		public static extern DWord CheckMenuItem(HMenu menu, uint32 uIDCheckItem, AppendMenuFlags uCheck);

		[Import("Gdi32.lib"), CLink, CallingConvention(.Stdcall)]
		public static extern HBitmap CreteBitmap(int32 nWidth, int32 nHeight, uint32 nPlanes, uint32 nBitCount, void* lpBits);



		[Import("User32.lib"), CLink, CallingConvention(.Stdcall)]
		public static extern Atom RegisterClassA(WndClassA *lpWndClass);

		[Import("User32.lib"), CLink, CallingConvention(.Stdcall)]
		public static extern Windows.HWnd CreateWindowExA(ExWndStyle dwExStyle, LpCStr lpClassName, LpCStr lpWindowName, WndStyle dwStyle, int x, int y, int nWidth, int nHeight, Windows.HWnd hWndParent, HMenu hMenu, HInstance hInstance, LpVoid lpParam);

		[Import("User32.lib"), CLink, CallingConvention(.Stdcall)]
		public static extern LResult DefWindowProcA(Windows.HWnd hWnd, uint32 msg, WParam wParam, LParam lParam);

		[Import("User32.lib"), CLink, CallingConvention(.Stdcall)]
		public static extern int32 GetClassName(Windows.HWnd hWnd, LpCStr lpClassName, int32 nMaxCount);



		// ------------------------------------------------------------------------------------ BEHAVIOR



		private static HInstance s_hInstance = 0;

		public static this()
		{
			s_hInstance = (HInstance)GetModuleHandleA(null); 
		}

		public static HInstance GetHInstance()
		{
			return s_hInstance;
		}
	}
}
