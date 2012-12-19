DMSocialContactsList
====================
An Objective-C contacts picker example which fetch local and Facebook contacts, merge and sort them. Plus handle selection and live search. Useful to send SMS, Email, Facebook invitation.

**Please note* It is more an example than a ready to use library.


##Features
1. Fetch local contacts
2. Fetch Facebook contacts
3. Merge local contacts and Facebook contacts
4. Sort them
5. Display contacts
6. Handle selection of emails, phones, Facebook id
7. Keep a list of selected contacts with their selected values
8. Display contact images (local or Facebook)
9. Real time search

##The purpose
We live in a social world, our mobile application need to be social too. In a lot of modern application you can invite your contacts to be your friends on your new shiny crapware ubber social applications. The mobile application then display a list of your contact (Local, Facebook, twitter, etc...) and you can send them invitations. **SPAM THEM**

It become critically to have this in your application if you want to create the next Instagram and make **$1 Billion**. Your application need to go viral! 

Well, this example show you how to easily load your local and Facebook contacts. It merge the contacts list and display them in a fast **UITableVIew**. In this list you can select any contact, it will display the selected contact email, phone, or Facebook. Once you selected the value it will register it so you can at the end of the selection send invitations to all the selected contacts. 

Sending invitations in on your part (Send SMS to number, email to email address and Facebook app request, wall post to Facebook id).

The correct way would be to send the selected contacts as a payload to your server, then it would dispatch invitations to the correct user using the correct method. 

##The user interface##

The user interface is simple and ugly but very functional. It follow the Apple guidelines. You have a simple list of contacts with a **UISearchBar** on top. Selecting a contact display a **UIActionSheet**. The **UITableView** clearly retain selected contacts. When you do a search result are shown instantly. There is no fancy things, no need too. 

Sure this example would be greatly improved with beautiful custom cells.

![image](https://raw.github.com/Dimillian/DMSocialContactsList/master/images/screen1.png)

![image](https://raw.github.com/Dimillian/DMSocialContactsList/master/images/screen2.png)

##How it works
First it load your local contacts with the Apple AddressBook framework. 
Then it load your Facebook friends list. It use the Facebook 3.1 framework. So if you don't have configured any Facebook account the iPhone or the simulator where you are testing this it will open the Facebook app to ask your the permission. 

I have created a model **DMContact** which contain a Facebook or local user. You can get a lot of information from it. List of emails and phones, Facebook id, first name, last name, composed name. It also have the local contact image data or the Facebook image URL. 
THe same model is used to instantiate a local contact or a Facebook contact. 

When all your local and Facebook contacts are loaded it finally merge them (Add Facebook ID to matched local contacts and insert missing Facebook contacts). 
So on one contact you can have en emails list, phones list, and it's associated Facebook ID.

The **DMContact** model also contain a **selectedValueRef**, when you select a contact from the contact list it ask you which value do you want to select (phone, email or Facebook ID). 
This property contain the selected value. 

So once the user is done selecting the contacts he want to invite you can send invitation to all those values. 

There is more, just read the code... :)

##How to use it
This is more an example than a ready to use library. Use it as a reference on how to load local contacts, Facebook contacts, sort and merge them. Handle selection in a UITableView etc...

To easiest way to simply use it in your project would be to extract the **DMContactListViewController** and **DMContact**, import them in your project. Add necessary frameworks (use my Xcode project as a reference) and personalize the XIB to match colors of your application. (Well if you know how to code proper iOS application it should not be too hard to extract the right things from my example).

If I have a lot of requests I will happily make a better drag & drop version where you simply customize the view, pass a few parameters and you're done. 

##TODO
1. Fetch and merge with Twitter contact
2. Optimize the merge algorithm
3. Make it more the "Drag & Drop way"

##Facebook note
In the **.plist** I've set an application id of my own. You need to replace it with your application id if you plan to start a real project on those foundation. 

###Linked framework

The Xcode project is configured and linked with 

1. [The Facebook framework (3.1)](https://developers.facebook.com/docs/getting-started/facebook-sdk-for-ios/3.1/)
2. [SDWebImage](https://github.com/rs/SDWebImage)




