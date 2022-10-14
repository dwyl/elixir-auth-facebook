<div align="center">

# `elixir-auth-facebook`  Comming Soon! See: [`#21`](https://github.com/dwyl/elixir-auth-facebook/issues/21)

![img](http://i.stack.imgur.com/pZzc4.png)

_Easily_ add `Facebook` login to your `Elixir` / `Phoenix` Apps 
with step-by-step  **_detailed_ documentation**.

![GitHub Workflow Status](https://img.shields.io/github/workflow/status/dwyl/auth/Elixir%20CI?label=build&style=flat-square)
[![codecov.io](https://img.shields.io/codecov/c/github/dwyl/auth/master.svg?style=flat-square)](http://codecov.io/github/dwyl/auth?branch=master)
[![Hex.pm](https://img.shields.io/hexpm/v/auth?color=brightgreen&style=flat-square)](https://hex.pm/packages/auth)
[![Libraries.io dependency status](https://img.shields.io/librariesio/release/hex/auth?logoColor=brightgreen&style=flat-square)](https://libraries.io/hex/auth)
[![docs](https://img.shields.io/badge/docs-maintained-brightgreen?style=flat-square)](https://hexdocs.pm/auth/api-reference.html)
[![contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat-square)](https://github.com/dwyl/auth/issues)
[![HitCount](http://hits.dwyl.com/dwyl/elixir-auth-facebook.svg)](http://hits.dwyl.com/dwyl/elixir-auth-facebook)

</div>

## Why?

Facebook authentication is used ***everywhere***!
We wanted to create a reusable `Elixir` package 
with beginner-friednly instructions and readable code.

## What?

A simple and easy-to-use `Elixir` package 
that gives you 
**Facebook `OAuth` Authentication** 
in a few steps.

> If you're new to `Elixir`, 
> please see: [dwyl/**learn-elixir**](https://github.com/dwyl/learn-hapi)

## How?

<hr />

# ⚠️ WARNING: This is out-of-date see: [`#21`](https://github.com/dwyl/elixir-auth-facebook/issues/21)


<hr />



These instructions will guide you through setup in 6 simple steps
by the end you will have 
**login with `Facebook`** 
working in your App.
No prior experience/knowledge
is expected/required.

> **Note**: if you get stuck,
> please let us know by opening an issue! 



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

### Step 6: Make a request in your `Elixir` / `Phoenix` server

In your `Phoenix` server, make a request to the following url specifying your individual ```app-id``` and ```redirect-uri```

![facebookRequest](https://files.gitter.im/jackcarlisle/hapi-auth-facebook/fkmD/Screenshot-from-2015-11-27-12_21_22.png)

