# hapi-auth-_facebook_ so you can: ![img](http://i.stack.imgur.com/pZzc4.png)
[![Build Status](https://travis-ci.org/dwyl/hapi-auth-facebook.svg)](https://travis-ci.org/dwyl/hapi-auth-facebook)

:+1: Easy Facebook Authentication for Hapi Apps

Facebook Hapi plugin with ***detailed documentation***.

## Why?

Facebook authentication is used ***everywhere***! We wanted to create a reusable Hapi Plugin with readable code.

## What?

A simple and easy Hapi plugin that gives you Facebook OAuth Authentication in a few steps.

> If you're new to Hapi, check out: https://github.com/dwyl/learn-hapi

## How?



### Tutorial

A guide for how we built an app to login with facebook with no prior knowledge.

### Step 1: Upgrade your personal Facebook account to a developer account

Go to developers.facebook.com/apps

![upgrade-account](https://files.gitter.im/jackcarlisle/hapi-auth-facebook/KNoV/facebook1.png)

...after logging in to your facebook account, you can 'Register Now' for a developer account.

### Step 2: Select what platform your app is on

![makeapp](https://files.gitter.im/jackcarlisle/hapi-auth-facebook/YOYX/facebook3.png)

### Step 3: Skip to create an App

On this page, you can click the button in the top right to quickly access your app's id.

![skip](https://files.gitter.im/jackcarlisle/hapi-auth-facebook/YOYX/facebook4.png)

### Step 4: Create App

Here you can specify your app's name (doesn't ***have*** to be unique!)

![nameapp](https://files.gitter.im/jackcarlisle/hapi-auth-facebook/YOYX/facebook5.png)

**Note**: Copy the App ID and the Secret into your ```.env``` file.

### Step 5: Specify Redirect URI

Inside the facebook app's **advanced** settings, specify the redirect URI near the *bottom* of the page:

![redirecturi](https://files.gitter.im/jackcarlisle/hapi-auth-facebook/QG8M/Screen-Shot-2015-11-27-at-12.21.57.png)

**Note**: the redirect URI has to be an *absolute* URI - make sure you include the ```http://``` prefix.

### Step 6: Make a request in your Hapi server

In your hapi server, make a request to the following url specifying your individual ```app-id``` and ```redirect-uri```

![facebookRequest](https://files.gitter.im/jackcarlisle/hapi-auth-facebook/fkmD/Screenshot-from-2015-11-27-12_21_22.png)
