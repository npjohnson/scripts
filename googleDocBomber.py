#!/usr/bin/env python2

import urllib

num_responses = '22'
url = 'https://docs.google.com/forms/d/e/1FAIpQLSdHIM1ISzuZjosf6_23lyGuoDTEf6eeTTtI44LE0Uo-WqG5iw/formResponse?usp=pp_url&entry.1091789143=26&entry.1172671696=No&entry.1875900423=3&entry.177661477=No&entry.887864255=Yes&entry.2119033811=$65&entry.1109056081=$75&entry.1694439150=Yes&entry.1183303744=Online+(Amazon,+Retailer+Website)'

def fillOut():
	getSite = urllib.urlopen(url)

def loop(N):
	for x in range(0, N):
		fillOut()

loop(num_responses)
