#!/usr/bin/env python2
## Build servers use python2, and python3 actually changes the results
### LineageOS Build Day Calculator
## Imports
import calendar
import random

## Variables
# We use 7 for W, 28 for M, but we currently use W
buckets=7
# Build taret name, not variant (eg. klteactivexx not klteattactive)
codename=raw_input("Device codename?\n")
print("\n")

## Get the numeric day of the week
day_number=random.Random(codename).randint(1, buckets)

## Convert the day of week to expected format, we use 1,7, and `calendar` assumes Monday = 0, so account for that
day=calendar.day_name[day_number-1]

## Print the day of the week
print(day)
