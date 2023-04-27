# Guided Rec

Guided Rec is our questionnaire-based recommendations, where we develop a nominal profile based on the customer's selected choices. Get Recs does not require an identified customer with a ``Profile``. 


``GuidedRec`` is a quiz that gets returned by ``Preferabli/getGuidedRec(guided_rec_id:onCompletion:onFailure:)``. Each question ``GuidedRecQuestion`` of that quiz has choices ``GuidedRecChoice``. Those choices are then used to generate results from ``Preferabli/getGuidedRecResults(guided_rec_id:selected_choice_ids:price_min:price_max:collection_id:include_merchant_links:onCompletion:onFailure:)``.

## Topics

### Related Classes

- ``GuidedRec``
- ``GuidedRecQuestion``
- ``GuidedRecChoice``
