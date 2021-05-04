# jab-me
**Get your damn vaccine on time by a notification reminder.**

![NOTIF_EX](https://github.com/gauravat16/jab-me/blob/master/screenshots/notif-ex.png)

**Usage**

--m: mode,

--pincode: pincode for the centre,

--district: district code (To get this number please run the script in manual mode and check resources/district.json

--age-max: Max age for vaccination

--h: help



**Via Pincode**

bash  Vaccinator.sh --m A --pincode 201014 --age-max 44

**Via District id**

How to find the district id?

1. run : bash  Vaccinator.sh --m M
2. Follow the steps till the end.
3. cat resources/districts.json | grep -i 'District-Name'  ex : cat resources/districts.json | grep -i 'Ghaziabad'

bash  Vaccinator.sh --m A --district 650 --age-max 999



