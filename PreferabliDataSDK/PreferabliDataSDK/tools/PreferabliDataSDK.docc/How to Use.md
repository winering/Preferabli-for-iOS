# How to use

After <doc:Installation> of the SDK, read the following to familiarize yourself with how to use the SDK.

## Overview

``Preferabli`` is the primary class you will utilize to access the Preferabli Data SDK.

Grab the instance ``Preferabli/main`` to get started. This will unlock all of Preferabli's functionalities. For example:

```
Preferabli.main.logout()
```

By default, when the SDK is initialized, an anonymous session is created. This anonymous session allows immediate access to any of the <doc:How-to-Use#Unauthenticated-Actions>. These functions *do not* return personalized results that are based on a customer's ``Profile``.

You do not need to authenticate a user to use the SDK. However, once a user is authenticated, you are able to unlock several user-centric functions.

The SDK supports two different types of users:

- ``Customer``: authenticate your customers as you usually do, then pass us their identifier (usually email or phone) and the verification hash provided by your API. See <doc:How-to-Use#Customer-Management>.

- ``PreferabliUser``: pass us a user's Preferabli account email / password and we handle the authentication process. See <doc:How-to-Use#Preferabli-User-Management>.

Once a user is authenticated, you can immediately start using any of <doc:How-to-Use#Authenticated-Actions>. These functions return personalized results for your ``Customer``.

Please note that once a user has been authenticated as a ``Customer``, that ``Customer`` state persists across sessions until you call ``Preferabli/logout(onCompletion:onFailure:)``.

All of our functions are thread safe and return results through a completion block:

```
Preferabli.main.searchProducts(query: "wine") { products in
    // Do what you want with the products returned.
} onFailure: { error in
    // Call failed.
}
```

For more examples on how to use the SDK, please see the [demo application](https://github.com/winering/Preferabli-for-iOS).

## Functions


### Customer Management

Use these functions to manage a ``Customer``. 

- ``Preferabli/loginCustomer(merchant_customer_identification:merchant_customer_verification:onCompletion:onFailure:)``
- ``Preferabli/logout(onCompletion:onFailure:)``

### Preferabli User Management

Use these functions to manage a ``PreferabliUser``.

- ``Preferabli/loginPreferabliUser(email:password:onCompletion:onFailure:)``
- ``Preferabli/signupPreferabliUser(email:password:user_claim_code:cellar_name:onCompletion:onFailure:)``
- ``Preferabli/forgotPassword(email:onCompletion:onFailure:)``
- ``Preferabli/logout(onCompletion:onFailure:)``


### Unauthenticated Actions

These functions return generic, non user-specific results.

- ``Preferabli/searchProducts(query:lock_to_integration:product_categories:product_types:include_merchant_links:onCompletion:onFailure:)``
- ``Preferabli/labelRecognition(image:include_merchant_links:onCompletion:onFailure:)``
- ``Preferabli/getGuidedRec(guided_rec_id:onCompletion:onFailure:)``
- ``Preferabli/getGuidedRecResults(selected_choice_ids:price_min:price_max:collection_id:include_merchant_links:onCompletion:onFailure:)``
- ``Preferabli/whereToBuy(product_id:fulfill_sort:append_nonconforming_results:lock_to_integration:onCompletion:onFailure:)``
- ``Preferabli/lttt(product_id:year:collection_id:onCompletion:onFailure:)``


### Authenticated Actions

These functions require an authenticated user. They are user specific actions that help deliver a personalized experience.

- ``Preferabli/rateProduct(product_id:year:rating:location:notes:price:quantity:format_ml:onCompletion:onFailure:)``
- ``Preferabli/wishlistProduct(product_id:year:location:notes:price:format_ml:onCompletion:onFailure:)``
- ``Preferabli/getProfile(force_refresh:onCompletion:onFailure:)``
- ``Preferabli/getFoods(force_refresh:onCompletion:onFailure:)``
- ``Preferabli/getRecs(product_category:product_type:price_min:price_max:collection_id:style_ids:food_ids:include_merchant_links:onCompletion:onFailure:)``
- ``Preferabli/getRatedProducts(force_refresh:include_merchant_links:onCompletion:onFailure:)``
- ``Preferabli/getWishlistProducts(force_refresh:include_merchant_links:onCompletion:onFailure:)``
- ``Preferabli/getPurchaseHistory(force_refresh:lock_to_integration:include_merchant_links:onCompletion:onFailure:)``
- ``Preferabli/editTag(tag_id:tag_type:year:rating:location:notes:price:quantity:format_ml:onCompletion:onFailure:)``
- ``Preferabli/deleteTag(tag_id:onCompletion:onFailure:)``

### Static Functions

The Preferabli class also provides these helpful class utility methods:

- ``Preferabli/isPreferabliUserLoggedIn()``
- ``Preferabli/isCustomerLoggedIn()``
- ``Preferabli/getPrimaryInventoryId()``
- ``Preferabli/getPoweredByPreferabliLogo(light_background:)``
- ``Preferabli/getPreferabliProductId(merchant_product_id:merchant_variant_id:onCompletion:onFailure:)``

These are called without the ``Preferabli/main`` instance.

```
Preferabli.isCustomerLoggedIn()
```
