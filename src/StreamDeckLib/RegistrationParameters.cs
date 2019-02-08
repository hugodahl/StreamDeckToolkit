namespace StreamDeckLib
{

	public class RegistrationParameters
	{
		public RegistrationParameters(int port, string pluginUUID, string info, string registerEvent)
		{
			this.Port          = port;
			this.PluginUUID    = pluginUUID;
			this.Info          = info;
			this.RegisterEvent = registerEvent;
		}

		/// <summary>
		/// The TCP port which is used to communicate with the Stream Deck software
		/// </summary>
		public int Port { get; }
		
		/// <summary>
		/// The UUID of the plugin registered
		/// </summary>
		public string PluginUUID { get; }
		
		/// <summary>
		/// Some information about the registration(?)
		/// </summary>
		public string Info { get; }
		
		/// <summary>
		/// Event registration information(?)
		/// </summary>
		public string RegisterEvent { get; set; }
	}

}