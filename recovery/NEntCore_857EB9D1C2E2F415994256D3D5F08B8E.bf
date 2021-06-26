using System;
using System.Collections;
using System.Diagnostics;
using SDL2;



namespace NEnt
{
	class NEntCore
	{
		private PixelKun m_pk;
		private EmuMan m_em;
		private bool m_running;



		public this()
		{

		}

		public ~this()
		{
		}

		public void Init(String[] args)
		{
			m_pk = new .();

			m_pk.Init(256, 224, 4);
			m_pk.InitMenu();
			m_pk.Blit();

			m_em = new EmuNES();
			m_em.BaseInit(m_pk);
			m_em.EmuInit();

			SDL.EventState(.SysWMEvent, .Enable);

		}

		public void Run()
		{
			uint32 i = 0;
			SDL.Event event;

			m_running = true;

			Rom r = scope .();
			m_em.Run(m_pk, r);

			

			while(m_running)
			{
				// SDL.Delay(10);

				while(SDL.PollEvent(out event) != 0)
				{
					HandleEvent(event);
				}

				m_pk.SetPixel(i % m_pk.GetBufferWidth(), i / m_pk.GetBufferWidth(), 0xFF0000);
				m_pk.Blit();

				++i;
			}
		}

		public void DeInit()
		{
			//MenuItem.DeInit();

			delete m_pk;
			delete m_em;
		}

		private void HandleEvent(SDL.Event event)
		{
			switch (event.type)
			{
			case .Quit:
				m_running = false;

			case .SysWMEvent:
				SDLMessage* sm = (SDLMessage*)event.syswm.msg;

				switch (sm.msg.msg)
				{
				case .Command:
					uint32 id = (uint32)NEntWin.LoWord(sm.msg.wParam);
					Debug.WriteLine("Invoked menu command ID: {}", id);

					MenuItem.InvokeCommand(id, sm.msg);
					break;

				default:
					break;
				}

				break;

			default:
				break;
			}
		}
	}
}
