#include "gpo_config.h"

const char GPO_CONFIG::keys[rows][cols] = {
    {'1', '2', '3', 'A'},
    {'4', '5', '6', 'B'},
    {'7', '8', '9', 'C'},
    {'*', '0', '#', 'D'}
};

byte GPO_CONFIG::rowPins[rows] = {13, 12, 14, 27};
byte GPO_CONFIG::colPins[cols] = {26, 25, 33, 32};