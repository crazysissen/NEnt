using System;
using System.Collections;
using System.Diagnostics;

namespace NEnt
{
	abstract class MenuItem
	{
		private static uint32 s_idCounter = 0;
		private static Dictionary<uint32, MenuItem> s_menuItems =
			new Dictionary<uint32, MenuItem>();

		private uint32 m_id;
		private NEntWin.HMenu m_hMenu;

		public this()
		{
			m_id = s_idCounter++;
			m_hMenu = 0;

			s_menuItems.Add(m_id, this);
		}

		public ~this()
		{
			s_menuItems?.Remove(m_id);
		}

		public uint32 GetID()
			=> m_id;

		public void LoadMenuVar(NEntWin.HMenu hMenu)
			=> m_hMenu = hMenu;

		public virtual NEntWin.UIntPtr GetIDPtr()
			=> m_id;

		public virtual NEntWin.AppendMenuFlags GetFlags()
			=> .Enabled;

		protected NEntWin.HMenu GetMenuHandle()
			=> m_hMenu;

		protected virtual void Command(SDLMessage.MSG msg)
		{
		}

		public static void InvokeCommand(uint32 id, SDLMessage.MSG msg)
		{
			if (!s_menuItems.ContainsKey(id))
			{
				Debug.WriteLine("Tried to invoke menu command with invalid or nonexistent ID: {}", id);
				return;
			}

			s_menuItems[id].Command(msg);
		}

		static ~this()
		{
			delete s_menuItems;

			s_menuItems = null;
		}
	}

	class MenuSpace : MenuItem
	{
		public this()
		{
		}

		public override NEntWin.AppendMenuFlags GetFlags()
		{
			return .Separator;
		}
	}

	/*class MenuBreak : MenuItem
	{
		private bool m_grayBar;

		public this(bool grayBar)
		{
			m_grayBar = grayBar;
		}

		public override NEntWin.AppendMenuFlags GetFlags()
		{
			return (m_grayBar ? .MenuBarBreak : .MenuBreak) | .Disabled;
		}
	}*/

	class MenuButton : MenuItem
	{
		delegate void() m_trigger;

		public this(String name, delegate void() trigger) : base()
		{
			m_trigger = trigger;
		}

		public ~this()
		{
			delete m_trigger;
		}

		protected override void Command(SDLMessage.MSG msg)
		{
			m_trigger();
		}
	}

	class MenuButtonIndexer : MenuItem
	{
		delegate void(int) m_trigger;
		private int m_index;

		public this(String name, int index, delegate void(int) trigger) : base()
		{
			m_trigger = trigger;
			m_index = index;
		}

		public ~this()
		{
			delete m_trigger;
		}

		protected override void Command(SDLMessage.MSG msg)
		{
			m_trigger(m_index);
		}
	}

	class MenuButtonMSG : MenuItem
	{
		delegate void(SDLMessage.MSG) m_trigger;

		public this(String name, delegate void(SDLMessage.MSG) trigger) : base()
		{
			m_trigger = trigger;
		}

		public ~this()
		{
			delete m_trigger;
		}

		protected override void Command(SDLMessage.MSG msg)
		{
			m_trigger(msg);
		}
	}

	class MenuCheckbox : MenuItem
	{
		private delegate void(bool) m_trigger;
		private bool m_state;

		public this(String name, bool defaultState, delegate void(bool) newStateTrigger) : base()
		{									 
			m_trigger = newStateTrigger;
			m_state = defaultState;
		}

		public ~this()
		{
			delete m_trigger;
		}

		protected override void Command(SDLMessage.MSG msg)
		{
			SetState(!m_state);
		}

		public override NEntWin.AppendMenuFlags GetFlags()
		{
			return m_state ? .Checked : .Unchecked;
		}

		public void SetState(bool state)
		{
			NEntWin.DWord retID = NEntWin.CheckMenuItem(
				GetMenuHandle(),
				GetID(),
				(state ? .Checked : .Unchecked) | .ByCommand
			);

			if (retID == GetID())
			{
				m_state = state;
				m_trigger(m_state);
			}
		}
	}
}
