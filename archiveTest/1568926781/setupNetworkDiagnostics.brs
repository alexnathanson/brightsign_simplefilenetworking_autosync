' Network diagnostics test script

Sub AdvanceLine(rect as object, amount as integer)
  rect.SetY(rect.GetY() + amount)
end sub

Sub Geometry_Advance()
  m.left_rect.SetY(m.left_rect.GetY() + m.height + m.spacing)
  m.middle_rect.SetY(m.middle_rect.GetY() + m.height + m.spacing)
  m.right_rect.SetY(m.right_rect.GetY() + m.height + m.spacing)
end sub

Function Geometry_CreateWidgetTriplet(name as string)
  w = { }
  w.label = CreateObject("roTextWidget", m.left_rect, 1, 2, { Alignment: 0 })
  w.result = CreateObject("roTextWidget", m.middle_rect, 1, 2, { Alignment: 0 })
  w.info = CreateObject("roTextWidget", m.right_rect, 1, 2, { Alignment: 0 })
  w.name = name
  
  w.result.SetBackgroundColor(&h7f202020)
  w.info.SetBackgroundColor(&h7f69f542)
  
  w.label.PushString(name)
  w.result.PushString("")
  w.info.PushString("")
  
  border = m.right_rect.GetHeight() / 6
  r = CreateObject("roRectangle", border, border, m.right_rect.GetWidth() - border * 2, m.right_rect.GetHeight() - border * 2)
  w.info.SetSafeTextRegion(r)
  
  m.widgets.Push(w.label)
  m.widgets.Push(w.result)
  m.widgets.Push(w.info)
  
  m.Advance()
  
  return w
end function

Function Geometry_CreateTitle(text as string)
  title = CreateObject("roTextWidget", m.title_rect, 1, 2, { Alignment: 1 })
  title.PushString(text)
  m.widgets.Push(title)
  return title
end function

Function Geometry_CreatePrompt()
  m.Advance()
  
  rect = CreateObject("roRectangle", m.left_rect.GetX(), m.left_rect.GetY(), m.left_rect.GetWidth() + m.right_rect.GetWidth(), m.left_rect.GetHeight() * 0.75)
  
  prompt = CreateObject("roTextWidget", rect, 1, 2, { Alignment: 1 })
  m.widgets.Push(prompt)
  return prompt
end function

Sub Geometry_ShowAll()
  for each widget in m.widgets
    widget.Show()
  next widget
end sub

Function CreateGeometry()
  g = { }
  
  v = CreateObject("roVideoMode")
  
  lines = 7
  left = v.GetSafeX() + v.GetSafeWidth() / 16
  width = v.GetSafeWidth() - left * 2
  left_width = width / 6
  middle_width = width / 12
  g.height = v.GetSafeHeight() / 20
  g.spacing = g.height / 2
  top = v.GetSafeY() + (v.GetSafeHeight() - g.height * lines - g.spacing * (lines - 1)) / 2
  
  g.left_rect = CreateObject("roRectangle", left, top, left_width, g.height)
  g.middle_rect = CreateObject("roRectangle", left + left_width, top, middle_width, g.height)
  g.right_rect = CreateObject("roRectangle", left + left_width + middle_width, top, width - left_width - middle_width, g.height)
  g.title_rect = CreateObject("roRectangle", left, top - g.height * 2, width, g.height * 1.25)
  
  g.widgets = CreateObject("roArray", 0, true)
  
  g.Advance = Geometry_Advance
  g.CreateWidgetTriplet = Geometry_CreateWidgetTriplet
  g.CreateTitle = Geometry_CreateTitle
  g.ShowAll = Geometry_ShowAll
  g.CreatePrompt = Geometry_CreatePrompt
  return g
end function

Function CreateWidgets()
  left_alignment = { Alignment: 0 }
  centre_alignment = { Alignment: 1 }
  right_alignment = { Alignment: 0 }
  
  geometry = CreateGeometry()
  
  widgets = { }
  widgets.title = geometry.CreateTitle("Network Diagnostics?!?!?!?!")
  widgets.ethernet = geometry.CreateWidgetTriplet("Ethernet")
  widgets.ethernetConfiguration = geometry.CreateWidgetTriplet("  config")
  widgets.wifi = geometry.CreateWidgetTriplet("WiFi")
  widgets.wifiConfiguration = geometry.CreateWidgetTriplet("  config")
  widgets.internet = geometry.CreateWidgetTriplet("Internet")
  widgets.timeServer = geometry.CreateWidgetTriplet("Time")
  widgets.prompt = geometry.CreatePrompt()
  
  geometry.ShowAll()
  
  return widgets
end function


Sub WriteWidgetStatus(widget as object, status as string)
  
  widget.result.SetForegroundColor(&hff00)
  widget.result.Clear()
  widget.info.Clear()
  widget.info.PushString(status)
  
end sub


Sub FillWidgets(widgets as object, result as string, info as string)
  if result <> "FAIL" then
    widgets.result.SetForegroundColor(&hff00)
    widgets.result.Clear()
    widgets.info.Clear()
    widgets.result.PushString(result)
  else
    widgets.result.SetForegroundColor(&hff0000)
    widgets.result.Clear()
    widgets.info.Clear()
    widgets.result.PushString(result)
    widgets.info.PushString(info)
  end if
end sub

Sub ReportToWidgets(widgets as object, result as object)
  if result.ok then
    FillWidgets(widgets, "OK", "")
  else
    FillWidgets(widgets, "FAIL", result.diagnosis)
    print widgets.name; " log:"
    for each line in result.log
      print "  "; line
    next line
    print
  end if
end sub


Sub ClearWidget(widget as object)
  widget.result.Clear()
  widget.info.Clear()
  widget.result.SetForegroundColor(&hffffff)
end sub


Sub ClearWidgets(widgets as object)
  ClearWidget(widgets.ethernet)
  ClearWidget(widgets.ethernetConfiguration)
  ClearWidget(widgets.wifi)
  ClearWidget(widgets.wifiConfiguration)
  ClearWidget(widgets.internet)
  ClearWidget(widgets.timeServer)
end sub


Sub SetWidgetRunning(widget as object)
  widget.result.Clear()
  widget.result.PushString("...")
end sub


Function RunTests(widgets as object, testEthernet as boolean, testWireless as boolean, testInternet as boolean) as boolean
  
  allTestsPassed = true
  
  ClearWidgets(widgets)
  
  SetWidgetRunning(widgets.ethernet)
  if testEthernet then
    if0 = CreateObject("roNetworkConfiguration", 0)
    if0result = if0.TestInterface()
    ReportToWidgets(widgets.ethernet, if0result)
    allTestsPassed = allTestsPassed and if0result.ok
    
    ipAddress$ = "None"
    gateway$ = "None"
    dns$ = "None"
    
    if type(if0) = "roNetworkConfiguration" then
      cc = if0.GetCurrentConfig()
      if cc.ip4_address <> "" then
        ipAddress$ = cc.ip4_address
      end if
      if cc.ip4_gateway <> "" then
        gateway$ = cc.ip4_gateway
      end if
      if cc.dns_servers.Count() > 0 then
        dns$ = cc.dns_servers[0]
      end if
    end if
    
    ethernetConfiguration$ = "IP address = " + ipAddress$ + ", Gateway = " + gateway$ + ", DNS = " + dns$
    WriteWidgetStatus(widgets.ethernetConfiguration, ethernetConfiguration$)
    
  else
    FillWidgets(widgets.ethernet, "N/A", "")
    FillWidgets(widgets.ethernetConfiguration, "N/A", "")
  end if
  
  SetWidgetRunning(widgets.wifi)
  if testWireless then
    if1 = CreateObject("roNetworkConfiguration", 1)
    if if1 = invalid then
      FillWidgets(widgets.wifi, "Fail", "Wifi not found")
      allTestsPassed = false
    else
      if1result = if1.TestInterface()
      ReportToWidgets(widgets.wifi, if1result)
      allTestsPassed = allTestsPassed and if1result.ok
      
      ipAddress$ = "None"
      gateway$ = "None"
      dns$ = "None"
      
      if type(if1) = "roNetworkConfiguration" then
        cc = if1.GetCurrentConfig()
        if cc.ip4_address <> "" then
          ipAddress$ = cc.ip4_address
        end if
        if cc.ip4_gateway <> "" then
          gateway$ = cc.ip4_gateway
        end if
        if cc.dns_servers.Count() > 0 then
          dns$ = cc.dns_servers[0]
        end if
      end if
      
      wifiConfiguration$ = "IP address = " + ipAddress$ + ", Gateway = " + gateway$ + ", DNS = " + dns$
      WriteWidgetStatus(widgets.wifiConfiguration, wifiConfiguration$)
    end if
  else
    FillWidgets(widgets.wifi, "N/A", "")
    FillWidgets(widgets.wifiConfiguration, "N/A", "")
  end if
  
  systemTime = CreateObject("roSystemTime")
  dateTime = systemTime.GetLocalDateTime()
  
  if type(if0) = "roNetworkConfiguration" then
    WriteWidgetStatus(widgets.timeServer, if0.GetTimeServer() + ", " + dateTime)
  else if type(if1) = "roNetworkConfiguration" then
    WriteWidgetStatus(widgets.timeServer, if1.GetTimeServer() + ", " + dateTime)
  end if
  
  SetWidgetRunning(widgets.internet)
  if testInternet then
    internetTestPassed = false
    if testEthernet and type(if0) = "roNetworkConfiguration" then
      net_result = if0.TestInternetConnectivity()
      ReportToWidgets(widgets.internet, net_result)
      allTestsPassed = allTestsPassed and net_result.ok
      internetTestPassed = net_result.ok
    else if testWireless and type(if1) = "roNetworkConfiguration" then
      net_result = if1.TestInternetConnectivity()
      ReportToWidgets(widgets.internet, net_result)
      allTestsPassed = allTestsPassed and net_result.ok
      internetTestPassed = net_result.ok
    else
      FillWidgets(widgets.internet, "N/A", "")
    end if
  else
    FillWidgets(widgets.internet, "N/A", "")
  end if
  
  ' if the internet test was enabled and it passes, then proceed, even if other tests failed
  if testInternet and internetTestPassed then
    allTestsPassed = true
  end if
  
  return allTestsPassed
  
end function


Sub PerformNetworkDiagnostics(testEthernet as boolean, testWireless as boolean, testInternet as boolean)
  
  widgets = CreateWidgets()
  
  msgPort = CreateObject("roMessagePort")
  controlPort = CreateObject("roControlPort", "BrightSign")
  controlPort.SetPort(msgPort)
  
  while true
    
    widgets.prompt.Hide()
    allTestsPassed = RunTests(widgets, testEthernet, testWireless, testInternet)
    if allTestsPassed then
      widgets.prompt.PushString("Tests passed - proceeding...")
      widgets.prompt.Show()
      REM was 4000
      sleep(10000)
      return
    end if
    
    remainingSeconds% = 30
    
    while remainingSeconds% > 0
      widgets.prompt.PushString("Restarting test in" + stri(remainingSeconds%) + " seconds")
      widgets.prompt.Show()
      msg = wait(1000, msgPort)
      if type(msg) = "roControlDown" and msg.GetInt() = 12 then
        exit while
      end if
      remainingSeconds% = remainingSeconds% - 1
    end while
    
  end while
  
end sub

