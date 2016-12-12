//
//  IRKeyCode.swift
//  huarui
//
//  Created by sswukang on 15/4/1.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import Foundation

enum HRTVKeyCode: Byte{
    /* TV */
    case  NumZero       = 0x00;
    case  NumOne		= 0x01;
    case  NumTwo		= 0x02;
    case  NumThree      = 0x03;
    case  NumFour		= 0x04;
    case  NumFive		= 0x05;
    case  NumSix		= 0x06;
    case  NumSeven      = 0x07;
    case  NumEight      = 0x08;
    case  NumNine		= 0x09;
    /**待机键*/
    case  StandBy		= 0x0a;
    /**菜单键*/
    case  Menu          = 0x0b; // 菜单键
    /**返回键*/
    case  Return		= 0x0c; // 返回键
    case  DpadOk		= 0x0d; // 确定键
    /**设置键*/
    case  Set           = 0x0e; // 设置键
    /**静音键*/
    case  Mute          = 0x0f; // 静音键
    /**主页键*/
    case  HomePage      = 0x10; // 主页键
    case  VolumeAdd     = 0x11; // 音量+键
    case  VolumeSub     = 0x12; // 音量-键
    case  ChannelAdd	= 0x13; // 频道+键
    case  ChannelSub	= 0x14; // 频道-键
    case  DpadLeft      = 0x15; // 左键
    case  DpadRight     = 0x16; // 右键
    case  DpadUp		= 0x17; // 上键
    case  DpadDown      = 0x18; // 下键
    /**-/--键*/
    case  SingleAndDouble   = 0x27; // -/--键
    /**所有TV键*/
    case  AllTV             = 0xff; // 所有TV键
    

}

enum HRAirKeyCode: Byte{
    /* Air */
    case  PowerOff    = 0x00;// 电源关
    case  PowerOn     = 0x01;// 电源开
    case  ModeAuto    = 0x02;// 模式：自动
    case  ModeCooling = 0x03;// 模式：制冷
    case  ModeDrying  = 0x04;// 模式：除湿
    case  ModeVenting = 0x05;// 模式：送风
    case  ModeHeating = 0x06;// 模式：制暖
    case  SpeedAuto   = 0x07;// 风速：自动
    case  SpeedLow    = 0x08;// 风速：1档(低)
    case  SpeedMiddle = 0x09;// 风速：2档(中)
    case  SpeedHigh   = 0x0a;// 风速：3档(高)
    case  SwingAuto   = 0x0b;// 风向：自动摆风
    case  SwingHand   = 0x0c;// 风向：手动摆风
    case  Celsius16   = 0x10;//温度16
    case  Celsius17   = 0x11;
    case  Celsius18   = 0x12;
    case  Celsius19   = 0x13;
    case  Celsius20   = 0x14;
    case  Celsius21   = 0x15;
    case  Celsius22   = 0x16;
    case  Celsius23   = 0x17;
    case  Celsius24   = 0x18;
    case  Celsius25   = 0x19;
    case  Celsius26   = 0x1a;
    case  Celsius27   = 0x1b;
    case  Celsius28   = 0x1c;
    case  Celsius29   = 0x1d;
    case  Celsius30   = 0x1e;
    case  AllAirKeys  = 0xff;// 所有Air键
}