/// Default payment email templates (match backend email.service.ts).
/// Used in create deal and edit deal modals.
/// Placeholders: {dealTitle}, {amount}, {accountOwner}, {iban}, {reference}, {additionalInstructions}
const defaultPaymentEmailSubject = 'Payment instructions for deal "{dealTitle}"';
const defaultPaymentEmailBody = '''Dear customer,

Thank you for participating in the group deal "{dealTitle}".
Your total amount for this deal is {amount} EUR.

Please transfer the amount using the following payment details:

Account holder: {accountOwner}
IBAN: {iban}
Amount: {amount} EUR
Payment reference: {reference}

{additionalInstructions}

Best regards,
Your wholesaler team''';
