# jab-me
**Get your damn vaccine on time by a notification reminder.**

**NOTE: Only tested on macOS and Ubuntu.**

![NOTIF_EX](https://github.com/gauravat16/jab-me/blob/master/screenshots/notif-ex.png)

## Telegram Support
I have created a telegram channel where this script will post the notification.

Link : https://t.me/jab_me

Please be respectful of others and of the cowin platform and don't set up cron for every minute!


`bash    Vaccinator.sh --m A --pincode 201010 --age-max 99 --notif TELEGRAM`

**Usage**

--m: mode,

--pincode: pincode for the centre,

--district: district code (To get this number please run the script in manual mode and check resources/district.json

--age-max: Max age for vaccination

--notif: Notification Options: Desktop notifications (DESKTOP) (Deafult) or Telegram (TELEGRAM)

--h: help


**Via Pincode**

bash  Vaccinator.sh --m A --pincode 201014 --age-max 44

**Via District id**

How to find the district id?

1. run : bash  Vaccinator.sh --m M
2. Follow the steps till the end.
3. cat resources/districts.json | grep -i 'District-Name'  ex : cat resources/districts.json | grep -i 'Ghaziabad'

bash  Vaccinator.sh --m A --district 650 --age-max 999

**Add a Cron**

1. Crontab -e
2. `* * * * * cd <path-to-this-dir>/jab-me && bash Vaccinator.sh --m A --district 312 --age-max 44`
3. ex : `* * * * * cd /Users/gaurav.js/scripts/jab-me && bash Vaccinator.sh --m A --district 312 --age-max 44`






