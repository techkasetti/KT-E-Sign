public with sharing class IdentityProviderService   {

    // =========================
    // AURA ENABLED METHODS
    // =========================

    /**
     * @description Validates a SAML response, creates/updates a user, and logs the session.
     * @param samlResponse The Base64 encoded SAML response.
     * @param relayState The relay state from the SAML flow.
     * @return A SAMLValidationResult object with the status and authenticated user.
     */
    @AuraEnabled
    public static SAMLValidationResult validateSAMLAssertion(String samlResponse, String relayState) {
        try {
            String decodedSAML = EncodingUtil.base64Decode(samlResponse).toString();
            Map<String, String> userAttributes = parseSAMLAttributes(decodedSAML);

            // In production, this requires robust XML parsing and signature validation.
            if (!validateSAMLSignature(decodedSAML) || !validateSAMLTiming(decodedSAML)) {
                return new SAMLValidationResult(false, 'SAML signature or timing validation failed', null);
            }

            User samlUser = createOrUpdateSAMLUser(userAttributes);

            SAML_Session__c session = new SAML_Session__c(
                User_Id__c = samlUser.Id, // CORRECTED: Removed invalid markdown syntax
                SAML_Response__c = samlResponse,
                Identity_Provider__c = userAttributes.get('issuer'),
                Session_Index__c = userAttributes.get('sessionIndex'),
                Name_ID__c = userAttributes.get('nameId'),
                Session_Start__c = System.now(), // CORRECTED: Removed invalid markdown syntax
                Relay_State__c = relayState,
                IP_Address__c = getClientIPAddress()
            );
            insert session;

            AuditTrailManager.logSystemActivity('SAML_AUTHENTICATION_SUCCESS', 'User ' + samlUser.Email + ' authenticated via SAML.'); // CORRECTED
            return new SAMLValidationResult(true, 'SAML authentication successful', samlUser);
        } catch (Exception e) {
            AuditTrailManager.logSystemActivity('SAML_AUTHENTICATION_FAILED', 'SAML authentication failed: ' + e.getMessage());
            return new SAMLValidationResult(false, 'SAML authentication failed: ' + e.getMessage(), null);
        }
    }

    /**
     * @description Exchanges an OAuth authorization code for an access token.
     * NOTE: Assumes the Named Credential 'OAuth_Provider' is configured with OAuth 2.0 authentication,
     * which handles the client secret automatically.
     */
    @AuraEnabled
    public static OAuthTokenResult exchangeOAuthCode(String authorizationCode, String redirectUri, String clientId) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:OAuth_Provider/token');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

            // CORRECTED: The client_secret is automatically handled by a properly configured Named Credential.
            // Manually adding it here is incorrect and will cause errors.
            String requestBody = 'grant_type=authorization_code'
                + '&code=' + EncodingUtil.urlEncode(authorizationCode, 'UTF-8')
                + '&redirect_uri=' + EncodingUtil.urlEncode(redirectUri, 'UTF-8')
                + '&client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8');
            req.setBody(requestBody);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> tokenResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                String accessToken = (String) tokenResponse.get('access_token');
                String refreshToken = (String) tokenResponse.get('refresh_token');
                Integer expiresIn = (Integer) tokenResponse.get('expires_in');

                Map<String, Object> userInfo = getUserInfoFromOAuth(accessToken);
                User oauthUser = createOrUpdateOAuthUser(userInfo);

                OAuth_Token__c tokenRecord = new OAuth_Token__c(
                    User_Id__c = oauthUser.Id, // CORRECTED
                    Access_Token_Hash__c = generateTokenHash(accessToken),
                    Refresh_Token_Hash__c = generateTokenHash(refreshToken),
                    Expires_In__c = expiresIn,
                    Token_Type__c = (String) tokenResponse.get('token_type'),
                    Scope__c = (String) tokenResponse.get('scope'),
                    Issued_At__c = System.now(), // CORRECTED
                    Identity_Provider__c = 'OAuth_Provider'
                );
                insert tokenRecord;

                AuditTrailManager.logSystemActivity('OAUTH_AUTHENTICATION_SUCCESS', 'User ' + oauthUser.Email + ' authenticated via OAuth.');
                return new OAuthTokenResult(true, 'OAuth authentication successful', oauthUser, tokenRecord);
            } else {
                throw new CalloutException('OAuth token exchange failed: HTTP ' + res.getStatusCode() + ' - ' + res.getBody());
            }
        } catch (Exception e) {
            AuditTrailManager.logSystemActivity('OAUTH_AUTHENTICATION_FAILED', 'OAuth authentication failed: ' + e.getMessage());
            return new OAuthTokenResult(false, 'OAuth authentication failed: ' + e.getMessage(), null, null);
        }
    }

    /**
     * @description Authenticates a signature request using a SAML response.
     */
    @AuraEnabled
    public static AuthenticationResult authenticateWithSAML(String samlResponse, Id signatureRequestId) {
        try {
            String decodedSAML = EncodingUtil.base64Decode(samlResponse).toString();
            Map<String, String> samlAttributes = parseSAMLResponse(decodedSAML);

            if (!validateSAMLSignature(decodedSAML)) {
                return new AuthenticationResult(false, 'Invalid SAML signature', null);
            }

            Identity_Verification__c verification = new Identity_Verification__c(
                Signature_Request__c = signatureRequestId,
                Identity_Provider__c = 'SAML',
                Provider_User_ID__c = samlAttributes.get('NameID'),
                Verification_Status__c = 'VERIFIED',
                Verification_Details__c = JSON.serialize(samlAttributes),
                Verification_Date__c = System.now() // CORRECTED
            );
            insert verification;

            Signature_Request__c request = new Signature_Request__c(Id = signatureRequestId);
            request.Identity_Verification__c = verification.Id; // CORRECTED
            request.Authentication_Level__c = 'HIGH';
            update request;

            return new AuthenticationResult(true, 'SAML authentication successful', verification.Id); // CORRECTED
        } catch (Exception e) {
            System.debug('SAML authentication error: ' + e.getMessage());
            return new AuthenticationResult(false, 'SAML authentication failed: ' + e.getMessage(), null);
        }
    }

    /**
     * @description Authenticates a signature request using an OAuth access token from a supported provider.
     */
    @AuraEnabled
    public static AuthenticationResult authenticateWithOAuth(String accessToken, String provider, Id signatureRequestId) {
        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();

            switch on provider.toLowerCase() {
                when 'google' {
                    req.setEndpoint('https://www.googleapis.com/oauth2/v1/userinfo'); // CORRECTED
                }
                when 'microsoft' {
                    req.setEndpoint('https://graph.microsoft.com/v1.0/me'); // CORRECTED
                }
                when 'linkedin' {
                    req.setEndpoint('https://api.linkedin.com/v2/people/~'); // CORRECTED
                }
                when else {
                    return new AuthenticationResult(false, 'Unsupported OAuth provider.', null);
                }
            }

            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            HttpResponse res = http.send(req);

            if (res.getStatusCode() != 200) {
                return new AuthenticationResult(false, 'OAuth token validation failed: ' + res.getBody(), null);
            }

            Map<String, Object> userInfo = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            Identity_Verification__c verification = new Identity_Verification__c(
                Signature_Request__c = signatureRequestId,
                Identity_Provider__c = provider.toUpperCase(),
                Provider_User_ID__c = (String) userInfo.get('id'),
                Verification_Status__c = 'VERIFIED',
                Verification_Details__c = res.getBody(),
                Verification_Date__c = System.now() // CORRECTED
            );
            insert verification;

            return new AuthenticationResult(true, 'OAuth authentication successful', verification.Id); // CORRECTED
        } catch (Exception e) {
            System.debug('OAuth authentication error: ' + e.getMessage());
            return new AuthenticationResult(false, 'OAuth authentication failed: ' + e.getMessage(), null);
        }
    }

    // =========================
    // HELPER METHODS
    // =========================

    private static Map<String, String> parseSAMLAttributes(String decodedSAML) {
        // STUB: This is a placeholder. Production code requires robust XML parsing.
        return new Map<String, String>{
            'issuer' => 'TestIDP',
            'nameId' => 'user@test.com', // CORRECTED
            'sessionIndex' => 'abc123'
        };
    }

    private static Boolean validateSAMLSignature(String decodedSAML) {
        // STUB: This is a placeholder. Production requires cryptographic signature validation.
        return decodedSAML.contains('ds:Signature');
    }

    private static Boolean validateSAMLTiming(String decodedSAML) {
        // STUB: This is a placeholder. Production requires checking timestamps like NotBefore and NotOnOrAfter.
        return true;
    }

    private static User createOrUpdateSAMLUser(Map<String, String> attributes) {
        String email = attributes.get('nameId');
        if (String.isBlank(email)) return null;

        List<User> uList = [SELECT Id, Email FROM User WHERE Email = :email LIMIT 1];
        if (!uList.isEmpty()) return uList[0];

        User u = new User(
            LastName = 'SAMLUser',
            Email = email,
            Username = email,
            Alias = 'samluser',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US'
        );
        insert u;
        return u;
    }

    private static Map<String, Object> getUserInfoFromOAuth(String accessToken) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:OAuth_Provider/userinfo');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        Http http = new Http();
        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200) {
            return (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        }
        throw new CalloutException('Failed to get user info: HTTP ' + res.getStatusCode());
    }

    private static User createOrUpdateOAuthUser(Map<String, Object> userInfo) {
        String email = (String) userInfo.get('email');
        if (String.isBlank(email)) return null;

        List<User> uList = [SELECT Id, Email FROM User WHERE Email = :email LIMIT 1];
        if (!uList.isEmpty()) return uList[0];

        User u = new User(
            LastName = 'OAuthUser',
            Email = email,
            Username = email,
            Alias = 'oauthuser',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
          
            LanguageLocaleKey = 'en_US'
        );
        insert u;
        return u;
    }

    private static String generateTokenHash(String token) {
        return EncodingUtil.base64Encode(Crypto.generateDigest('SHA256', Blob.valueOf(token)));
    }

    private static String getClientIPAddress() {
        // STUB: In a real scenario, this would parse headers like 'True-Client-IP' or 'X-Forwarded-For'.
        return '127.0.0.1';
    }

    private static Map<String, String> parseSAMLResponse(String samlXML) {
        // STUB: Simplified parsing. A robust XML parser should be used in production.
        Map<String, String> attributes = new Map<String, String>();
        if (samlXML.contains('NameID')) {
            Integer startIndex = samlXML.indexOf('<saml:NameID') + samlXML.substring(samlXML.indexOf('<saml:NameID')).indexOf('>') + 1;
            Integer endIndex = samlXML.indexOf('</saml:NameID>');
            if (startIndex > 0 && endIndex > startIndex) {
                attributes.put('NameID', samlXML.substring(startIndex, endIndex));
            }
        }
        return attributes;
    }


    // =========================
    // INNER CLASSES (DTOs)
    // =========================

    public class SAMLValidationResult {
        @AuraEnabled public Boolean isValid;
        @AuraEnabled public String message;
        @AuraEnabled public User authenticatedUser;
        public SAMLValidationResult(Boolean isValid, String message, User user) {
            this.isValid = isValid;
            this.message = message;
            this.authenticatedUser = user;
        }
    }

    public class OAuthTokenResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public User authenticatedUser;
        public OAuth_Token__c tokenRecord;
        public OAuthTokenResult(Boolean success, String message, User user, OAuth_Token__c token) {
            this.success = success;
            this.message = message;
            this.authenticatedUser = user;
            this.tokenRecord = token;
        }
    }

    // CORRECTED: Added missing definition for AuthenticationResult
    public class AuthenticationResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public Id verificationId;
        public AuthenticationResult(Boolean success, String message, Id verificationId) {
            this.success = success;
            this.message = message;
            this.verificationId = verificationId;
        }
    }
}