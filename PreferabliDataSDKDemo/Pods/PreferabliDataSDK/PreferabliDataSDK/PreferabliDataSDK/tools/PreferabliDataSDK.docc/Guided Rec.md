# Guided Rec

These classes are all related to our Guided Rec functionality. 


``GuidedRec`` is a quiz that gets returned by ``Preferabli/getGuidedRec(guided_rec_id:onCompletion:onFailure:)``. Each question ``GuidedRecQuestion`` of that quiz has choices ``GuidedRecChoice``. Those choices are then used to generate results from ``Preferabli/getGuidedRecResults(selected_choice_ids:price_min:price_max:collection_id:include_merchant_links:onCompletion:onFailure:)``.

## Topics

### Related Classes

- ``GuidedRec``
- ``GuidedRecQuestion``
- ``GuidedRecChoice``
