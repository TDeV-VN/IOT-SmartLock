#pragma once

#include <Arduino.h>
struct Config {
    // Access point
    String apSSID;
    String apPassword;

    // Thời gian chờ nhập mã khóa
     static const long timeoutDuration = 60000; // 1 phút (60,000 ms)

     // số lần sai mã khóa liên tiếp sẽ bị báo động
    static const int maxWrongAttempts = 5; // 5 lần

     // Nếu nhập sai đủ số lần liên tiếp trong khoảng thời gian này thì sẽ bị vô hiệu hóa mã khóa: 30 phút, tính theo giây
     static const long wrongAttemptDuration = 1800; // 30 phút (1,800 giây)
     
     // thời gian vô hiệu hóa mã khóa
    static const long pinCodeDisableDuration = 1800; // 30 phút (1,800 giây)

    // thời gian còi báo động kêu khi truy cập trái phép
    static const long buzzerDuration = 60000; // 1 phút (60,000 ms)

    // thời gian còi báo động kêu khi mở khóa thành công
    static const long buzzerUnlockDuration = 2000; // 2 giây (2,000 ms)

    // thời gian còi báo động kêu khi mở khóa thất bại
    static const long buzzerFailDuration = 2000; // 2 giây (2,000 ms)

    // thời gian giữ khóa mở
    static const long relayDuration = 5000; // 5 giây (5,000 ms)
};