using System;
using System.Collections;
using SDL2;

namespace NEnt
{
	class PixelKun 
	{
		private const uint32 c_menuBarPixels 		= 20;
		private const uint32 c_pixelBytes 			= 3;
		private const uint32[4] c_rgbaByteMasks 	= 
		.(
			0xFF000000U, // R
			0x00FF0000U, // G
			0x0000FF00U, // B
			0x00000000U, // (A)
		);
		private const uint32[4] c_abgrByteMasks 	= 
		.(
			0x000000FFU, // R
			0x0000FF00U, // G
			0x00FF0000U, // B
			0x00000000U, // (A)
		);
		private const uint32[3] c_rgbByteMasks 	= 
		.(
			0xFF0000U, // R
			0x00FF00U, // G
			0x0000FFU  // B
		);



		// Member variables

		private bool m_initialized;

		private uint32 m_w;
		private uint32 m_h;
		private uint32 m_windowScale;

		private SDL.Window* m_window;
		private SDL.Surface* m_windowSurface;
		private SDL.Rect m_windowRect;
		private Windows.HWnd m_hWnd;

		private SDL.Renderer* m_renderer;

		private uint8* m_buffer;
		private SDL.Surface* m_bufferSurface;
		private SDL.Texture* m_bufferTexture;
		private SDL.Rect m_bufferRect;

		private MenuMain m_menu;



		public this()
		{
			m_initialized = false;
		}

		public ~this()
		{
			if (m_initialized)
			{
				delete m_buffer;
				delete m_menu;

				SDL.FreeSurface(m_bufferSurface);
				SDL.DestroyWindow(m_window);

				SDL.Quit();
			}
		}



		public void Init(uint32 w, uint32 h, uint32 windowScale, uint32 defaultColor = 0x6699FF)
		{
			m_w = w;
			m_h = h;
			m_windowScale = windowScale;

			// SDL Initialization
			if (!InitSDL())
			{
				System.Runtime.FatalError("SDL failed to initialize.");
			}

			// Window initialization
			if (!InitWindow())
			{
				System.Runtime.FatalError("Window failed to initialize.");
			}

			// Buffer initialization
			if (!InitBuffer(defaultColor))
			{
				System.Runtime.FatalError("Application back-buffer failed to initialize.");
			}

			/*if (!InitMenu())
			{
				System.Runtime.FatalError("Win32API menu failed to initialize.");
			}*/

			m_initialized = true;
		}

		public MenuMain InitMenu()
		{
			m_menu = new MenuMain(m_hWnd);

			Menu fileMenu = m_menu.AddSubMenu("File");
			fileMenu.AddButton("Load ROM...", new => FileButton);
			fileMenu.AddSubMenu("Load Previous");

			m_menu.AddSubMenu("Config");
			m_menu.AddSubMenu("Tools");
			m_menu.AddSubMenu("Help");

			m_menu.DrawMenu();

			return m_menu;
		}



		public void Blit()
		{
			SDL.UpdateTexture(m_bufferTexture, &m_bufferRect, m_buffer, (int32)(c_pixelBytes * m_w));

			SDL.RenderCopy(m_renderer, m_bufferTexture, &m_bufferRect, &m_windowRect);
			SDL.RenderPresent(m_renderer);
		}



		public void SetPixel(uint32 x, uint32 y, uint8 r, uint8 g, uint8 b)
		{
			uint32 startIndex = (x + y * m_w) * c_pixelBytes;

			m_buffer[startIndex] = r;
			m_buffer[startIndex + 1] = g;
			m_buffer[startIndex + 2] = b;
		}



		public void SetPixel(uint32 x, uint32 y, uint32 rgb, bool rgba = false)
		{
			if (x >= m_w || y >= m_h)
			{
				return;
			}

			if (rgba)
			{
				SetPixel(
					x, y,
					(uint8)((rgb & c_rgbaByteMasks[0]) >> 24),	// R
					(uint8)((rgb & c_rgbaByteMasks[1]) >> 16),	// G
					(uint8)((rgb & c_rgbaByteMasks[2]) >> 8)	// B
				);
			}
			else
			{
				SetPixel(
					x, y,
					(uint8)((rgb & c_rgbByteMasks[0]) >> 16),	// R
					(uint8)((rgb & c_rgbByteMasks[1]) >> 8),	// G
					(uint8)(rgb & c_rgbByteMasks[2])	// B
				);
			}
		}

		public uint32 GetBufferWidth()
			=> m_w;

		public uint32 GetBufferHeight()
			=> m_h;

		public uint32 GetScaledBufferWidth()
			=> m_w * m_windowScale;

		public uint32 GetScaledBufferHeight()
			=> m_h * m_windowScale;

		public uint32 GetWindowScale()
			=> m_windowScale;

		public MenuMain GetMenu()
			=> m_menu;

		public SDL.Rect GetTotalWindowRect()
		{
			NEntWin.WinRect r = .();
			NEntWin.GetWindowRect(m_hWnd, &r);

			return .(
				(int32)r.left,
				(int32)r.top,
				(int32)(r.right - r.left),
				(int32)(r.bottom - r.top)
			);
		}

		public SDL.Rect GetTotalClientRect()
		{
			NEntWin.WinRect r = .();
			NEntWin.GetClientRect(m_hWnd, &r);

			return .(
				(int32)r.left,
				(int32)r.top,
				(int32)(r.right - r.left),
				(int32)(r.bottom - r.top)
			);
		}

		public int GetMenuBarHeight()
		{
			int cyBorder = NEntWin.GetSystemMetrics(33);
			int cyCaption = NEntWin.GetSystemMetrics(4);

			NEntWin.WinRect windowRect = .();
			NEntWin.GetWindowRect(m_hWnd, &windowRect);

			NEntWin.WinPoint clientTopLeft = .();
			NEntWin.ClientToScreen(m_hWnd, &clientTopLeft);

			return clientTopLeft.y - windowRect.top - cyCaption - cyBorder;
		}



		// --------------------------------------------------------------------------------------------------------- 



		private bool InitSDL()
		{
			if (SDL.Init(.Video | .Audio | .Events) < 0)
			{
				return false;
			}

			SDL.EventState(.JoyAxisMotion, .Disable);
			SDL.EventState(.JoyBallMotion, .Disable);
			SDL.EventState(.JoyHatMotion, .Disable);
			SDL.EventState(.JoyButtonDown, .Disable);
			SDL.EventState(.JoyButtonUp, .Disable);
			SDL.EventState(.JoyDeviceAdded, .Disable);
			SDL.EventState(.JoyDeviceRemoved, .Disable);

			return true;
		}

		private bool InitWindow()
		{
			m_window = SDL.CreateWindow(
				"NEnt",
				.Undefined,
				.Undefined,
				(int32)(m_w * m_windowScale),
				(int32)(m_h * m_windowScale + c_menuBarPixels),
				.Shown | .Resizable
			);

			m_renderer = SDL.CreateRenderer(m_window, -1, 0);
			SDL.SetRenderDrawColor(m_renderer, 0, 0, 0, 255);
			SDL.RenderPresent(m_renderer);

			// SDL.SetWindowDisplayMode(m_window, )

			if (m_window == null)
			{
				return false;
			}

			// Setup surface and rect for drawing later

			m_windowSurface = SDL.GetWindowSurface(m_window);

			m_windowRect = SDL.Rect(
				0,
				0 /*c_menuBarPixels*/,
				(int32)(m_w * m_windowScale),
				(int32)(m_h * m_windowScale)
			);

			SDL.SDL_SysWMinfo wmInfo = SDL.SDL_SysWMinfo();
			SDL.VERSION(out wmInfo.version);
			SDL.GetWindowWMInfo(m_window, ref wmInfo);

			m_hWnd = wmInfo.info.win.window;

			return true;
		}

		private bool InitBuffer(uint32 defaultColor)
		{
			m_buffer = new uint8[m_w * m_h * c_pixelBytes]*;

			for (uint32 x = 0; x < m_w; ++x)
			{
				for (uint32 y = 0; y < m_h; ++y)
				{
					SetPixel(x, y, (x & y == 0) ? defaultColor : 0x000060);
				}
			}

			m_bufferSurface = SDL.CreateRGBSurfaceFrom(
				m_buffer,
				(int32)m_w, (int32)m_h,
				(int32)(c_pixelBytes * 8),
				(int32)(c_pixelBytes * m_w),
				c_abgrByteMasks[0],
				c_abgrByteMasks[1],
				c_abgrByteMasks[2],
				c_abgrByteMasks[3]
			);

			/*m_bufferTexture = SDL.CreateTextureFromSurface(
				m_renderer,
				m_bufferSurface
			);*/

			m_bufferTexture = SDL.CreateTexture(
				m_renderer,
				SDL.DEFINE_PIXELFORMAT(.ArrayU8, .ArrayOrderRGB, 0, 24, 3),
				0, // STATIC, streaming, target
				(int32)m_w,
				(int32)m_h
			);

			m_bufferRect = SDL.Rect(
				0,
				0,
				(int32)m_w,
				(int32)m_h
			);

			Blit();

			return true;
		}

		private void FileButton()
		{

		}
	}
}
