// Usage: onoff.exe on|off
// pavel_a 04-jan-2007, built with Vista RTM SDK, vs2005

#include "stdafx.h"
#include <windows.h>
#include <wlanapi.h>
#pragma comment( lib, "wlanapi.lib")

#define tprintf _tprintf

static PTSTR rs2str( DOT11_RADIO_STATE rs )
{
  switch(rs) {
  case dot11_radio_state_on: return TEXT("on");
  case dot11_radio_state_off: return TEXT("off");
  default: return TEXT("undef");
  }
}

static PTSTR ifstate2str( WLAN_INTERFACE_STATE rs )
{
  switch(rs) {
  default: return TEXT("undef");
  case wlan_interface_state_not_ready: return TEXT("not_ready");
  case wlan_interface_state_connected: return TEXT("connected");
  case wlan_interface_state_ad_hoc_network_formed: return TEXT("adhoc_formed");
  case wlan_interface_state_disconnecting: return TEXT("disconnecting");
  case wlan_interface_state_disconnected: return TEXT("not connected");
  case wlan_interface_state_associating: return TEXT("associating");
  case wlan_interface_state_discovering: return TEXT("discovering");
  case wlan_interface_state_authenticating: return TEXT("authenticating");
  }
}

void OnOff( int a_on )
{
  DWORD dwNegotiatedVersion = 0;
  HANDLE hClient = NULL;
  UINT i;
  DWORD r;

  PWLAN_INTERFACE_CAPABILITY pCapability = NULL;
  PWLAN_INTERFACE_INFO_LIST pIntfList = NULL;
  BOOL aenabled = FALSE, newstate = FALSE;

  r = WlanOpenHandle( WLAN_API_VERSION, NULL, &dwNegotiatedVersion, &hClient );
  if( ERROR_SUCCESS != r )
	 {
		tprintf( TEXT("Error opening Wlanapi=%u\n"), r );
		return;
	 }

  tprintf( _T("WlanAPI version available=%8.8x\n"), dwNegotiatedVersion );

  r = WlanEnumInterfaces(hClient, NULL, &pIntfList);

  if( ERROR_SUCCESS != r )
	 {
		tprintf( TEXT("Error in WlanEnumInterfaces=%u\n"), r );
		return;
	 }

  for( i = 0; i < pIntfList->dwNumberOfItems; i++ )
	 {
		PWLAN_INTERFACE_INFO pwi = &pIntfList->InterfaceInfo[i];
		PWSTR descr = pwi->strInterfaceDescription;
		GUID& guidIntf = pwi->InterfaceGuid;
		WLAN_INTERFACE_STATE st = pwi->isState;

		wprintf( TEXT("Adapter=[%s] state=%u (%s)\n"), descr, (UINT)st, ifstate2str(st) );

		if( st == wlan_interface_state_not_ready )
		  {
			 tprintf(TEXT("Interface not ready\n"));
			 continue;
		  }

		ULONG outsize = 0;
		PBOOL pb = NULL;

		r = WlanQueryInterface( hClient, &guidIntf, wlan_intf_opcode_autoconf_enabled, NULL, &outsize, (PVOID*)&pb, NULL );

		if( ERROR_SUCCESS != r )
		  {
			 tprintf( TEXT("Error WlanQueryInterface(autoconf) =%u\n"), r );
			 continue;
		  }

		aenabled = *pb & 0xFF;

		WlanFreeMemory( pb );

		tprintf( TEXT("Autoconfig enabled: %s\n"), aenabled ? _T("yes"):_T("no") );

		if( !a_on && aenabled )
		  {
			 newstate = 0; // FALSE
		  }

		if( a_on && !aenabled )
		  {
			 newstate = 0xFF; // TRUE
		  }

		r = WlanSetInterface( hClient, &guidIntf, wlan_intf_opcode_autoconf_enabled, 4, (PVOID)&newstate, NULL );

		if( r != ERROR_SUCCESS ) {
		  tprintf( TEXT("SetInterface error=%d\n"), r );
		  continue;
		}

		tprintf( TEXT("SetInterface ok\n") );


		BOOL flag = FALSE;		
		r = WlanSetInterface(hClient, &guidIntf, wlan_intf_opcode_background_scan_enabled, sizeof(BOOL), &flag, NULL);
		if( r != ERROR_SUCCESS ) {
		  tprintf( TEXT("Disable background error=%d\n"), r );
		  continue;
		}

		tprintf( TEXT("Disable background OK\n") );

		r = WlanQueryInterface( hClient, &guidIntf, wlan_intf_opcode_background_scan_enabled, NULL, &outsize, (PVOID*)&pb, NULL );

		if( ERROR_SUCCESS != r )
		  {
			 tprintf( TEXT("Error WlanQueryInterface(bgscan) =%u\n"), r );
			 continue;
		  }

		// NOTE: If the adapter was connected, it still stays connected;
		// WZC just won't touch it any longer.
		// We don't call WlanDisconnect because on XP this may convert an
		// automatic profile to on-demand (see MSDN)
		// After enabling WZC, you can restore connection manually,
		// or call WlanConnect with some profile or SSID.
	 }//for

  if (pIntfList != NULL) {
	 WlanFreeMemory(pIntfList);
  }

  if (hClient != NULL) {
	 WlanCloseHandle(hClient, NULL);
  }
}


int _tmain(int argc, _TCHAR* argv[])
{
  if( !argv[1] ) return 1;

  if( 0 == wcscmp( TEXT("off"), argv[1] ) ) {
	 OnOff( 0 );
  } else if( 0 == wcscmp( TEXT("on"), argv[1] ) ) {
	 OnOff( 1 );
  }
  else return 2;

  return 0;
}
