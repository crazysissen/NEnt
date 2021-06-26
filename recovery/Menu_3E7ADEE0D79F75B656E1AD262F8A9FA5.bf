using System;
using System.Diagnostics;
using System.Collections;

namespace NEnt
{
	class Menu : MenuItem
	{
		protected NEntWin.HMenu m_hMenu;
		protected Dictionary<String, MenuItem> m_items;
		protected Dictionary<String, Menu> m_menus;

		public this()
		{
			m_hMenu = NEntWin.CreateMenu();
			m_items = new Dictionary<String, MenuItem>();
			m_menus = new Dictionary<String, Menu>();
		}

		public ~this()
		{
			for (MenuItem item in m_items.Values)
			{
				delete item;
			}

			delete m_items;
			delete m_menus;
		}

		public T GetMenuItem<T>(String name) where T :  MenuItem
		{
			if (!m_items.ContainsKey(name))
			{
				Debug.WriteLine("Tried to get nonexistent menu item: {}", name);
				return null;
			}

			return m_items[name] as T;
		}

		public override NEntWin.UIntPtr GetIDPtr()
			=> (NEntWin.UIntPtr)m_hMenu;

		public void AddMenuItem(String name, MenuItem item, uint32? position = null, bool enabled = true)
		{
			m_items.Add(name, item);

			item.LoadMenuVar(m_hMenu);

			if (position == null)
			{
				Runtime.Assert(
					NEntWin.AppendMenuA(
						m_hMenu,
						.Popup | (enabled ? .Enabled : .Disabled) | item.GetFlags(),
						item.GetIDPtr(),
						name
					)
				);
			}
			else
			{
				Runtime.Assert(
					NEntWin.InsertMenuA(
						m_hMenu,
						position.Value,
						.Popup | (enabled ? .Enabled : .Disabled) | item.GetFlags() | .ByPosition,
						item.GetIDPtr(),
						name
					)
				);
			}
		}



		// ------------- Types


		
		public Menu AddSubMenu(String name, uint32? position = null, bool enabled = true)
		{
			Menu newMenu = new Menu();

			AddMenuItem(name, newMenu, position, enabled);

			m_menus.Add(name, newMenu);

			return newMenu;
		}

		/*public MenuBreak AddBreak(bool grayBar, uint32? position = null)
		{
			MenuBreak newBreak = new MenuBreak(grayBar);

			String name = scope String();
			name.AppendF("MenuBreak[{}]", newBreak.GetID());

			AddMenuItem(name, newBreak, position, true);

			return newBreak;
		}*/

		public MenuSpace AddSpace(uint32? position = null)
		{
			MenuSpace newSpace = new MenuSpace();

			String name = scope String();
			name.AppendF("MenuSpace[{}]", newSpace.GetID());

			AddMenuItem(name, newSpace, position, true);

			return newSpace;
		}

		public MenuButton AddButton(String name, delegate void() trigger, uint32? position = null, bool enabled = true)
		{
			MenuButton newButton = new MenuButton(name, trigger);

			AddMenuItem(name, newButton, position, enabled);

			return newButton;
		}

		public MenuButtonIndexer AddButtonIndexer(String name, int index, delegate void(int) trigger, uint32? position = null, bool enabled = true)
		{
			MenuButtonIndexer newButton = new MenuButtonIndexer(name, index, trigger);

			AddMenuItem(name, newButton, position, enabled);

			return newButton;
		}

		public MenuButtonMSG AddButtonMSG(String name, delegate void(SDLMessage.MSG) trigger, uint32? position = null, bool enabled = true)
		{
			MenuButtonMSG newButton = new MenuButtonMSG(name, trigger);

			AddMenuItem(name, newButton, position, enabled);

			return newButton;
		}

		public MenuCheckbox AddCheckbox(String name, bool defaultState, delegate void(bool) newStateTrigger, uint32? position = null, bool enabled = true)
		{
			MenuCheckbox newCheckbox = new MenuCheckbox(name, defaultState, newStateTrigger);

			AddMenuItem(name, newCheckbox, position, enabled);

			return newCheckbox;
		}
	}

	class MenuMain : Menu
	{
		private Windows.HWnd m_hWnd;

		public this(Windows.HWnd hWnd) : base()
		{
			m_hWnd = hWnd;

			Runtime.Assert(
				NEntWin.SetMenu(m_hWnd, m_hMenu)
			);
		}

		public ~this()
		{

		}

		public void DrawMenu()
		{
			Runtime.Assert(
				NEntWin.DrawMenuBar(m_hWnd)
			);
		}
	}
}
