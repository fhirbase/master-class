# JSONB tradeoffs

We pay some price for JSONB

* Lake of statistic
* Lake of some pg types :(
* how fast we access fields in jsonb?
* how much disk space we spend on jsonb?
* large json will be toasted

## Access fields

We will compare how quick we can access fields in:

* table column
* jsonb
* json
* composite type


## Disck space

We will compare disk space for:

* table column
* jsonb
* composite type

But it depends on your data.


Do not go to toasts

