public class AdvancedAIService {
    
public class AIResult {
public String generatedText;
public Decimal confidence;
public List<String> alternatives;
public List<String> complianceNotes;
public String rawResponse;
}

    
    // =====================================
    // AI Configuration Constants
    // =====================================
    private static final String AI_ENDPOINT             = 'callout:OpenAI_API';
    private static final String VECTOR_SEARCH_ENDPOINT  = 'callout:VectorSearch_API';
    private static final Integer MAX_CONTEXT_LENGTH     = 8000;
    private static final Integer EMBEDDING_DIMENSION    = 1536;
    
    
    // =====================================
    // Request / Response DTOs
    // =====================================
    
    /**
     * AI-Enhanced Clause Generation with Context Awareness.
     */
    public class AdvancedClauseRequest {
        public String contractType;
        public String region;
        public String role;
        public String industry;
        public String companySize;
        public List<String> existingClauses;
        public Map<String, String> contextVariables;
        public String brandVoice;
        public String tonePreference;
    }
    
    public class AIGeneratedClause {
        public String generatedText;
        public Decimal confidenceScore;
        public List<String> suggestedAlternatives;
        public List<String> complianceNotes;
        public String reasoning;
        public Map<String, Object> metadata;
    }
    
    
    // =====================================
    // Main Entry Point
    // =====================================
    
    @future(callout = true)
    public static void generateAdvancedClause(String requestJson, String configId) {
        try {
            AdvancedClauseRequest request = 
                (AdvancedClauseRequest) JSON.deserialize(requestJson, AdvancedClauseRequest.class);
            
            // Step 1: Build contextual prompt with vector search
            String contextualPrompt = buildContextualPrompt(request);
            
            // Step 2: Find similar clauses
            List<String> similarClauses = findSimilarClauses(request);
            
            // Step 3: Generate clause using advanced AI
            AIGeneratedClause result = callAdvancedAI(contextualPrompt, similarClauses, request);
            
            // Step 4: Validate and store result
            storeAIGeneratedResult(result, configId);
            
        } catch (Exception e) {
            System.debug('Advanced AI Generation Error: ' + e.getMessage());
            createAIErrorAudit(configId, e.getMessage());
        }
    }
    
    
    // =====================================
    // Prompt Construction
    // =====================================
    
    private static String buildContextualPrompt(AdvancedClauseRequest request) {
        StringBuilder promptBuilder = new StringBuilder();
        
        // Base context
        promptBuilder.append('Generate a ' + request.contractType + ' clause for ')
                     .append(request.region + ' jurisdiction, ')
                     .append(request.role + ' role in ' + request.industry + ' industry.\n\n');
        
        // Brand voice and tone
        if (String.isNotBlank(request.brandVoice)) {
            promptBuilder.append('Brand Voice: ' + request.brandVoice + '\n');
        }
        if (String.isNotBlank(request.tonePreference)) {
            promptBuilder.append('Tone: ' + request.tonePreference + '\n');
        }
        
        // Context variables
        if (request.contextVariables != null && !request.contextVariables.isEmpty()) {
            promptBuilder.append('Context Variables:\n');
            for (String key : request.contextVariables.keySet()) {
                promptBuilder.append('- ' + key + ': ' + request.contextVariables.get(key) + '\n');
            }
        }
        
        // Existing clauses
        if (request.existingClauses != null && !request.existingClauses.isEmpty()) {
            promptBuilder.append('\nExisting Contract Clauses for Reference:\n');
            for (String clause : request.existingClauses) {
                promptBuilder.append('- ' + clause.abbreviate(200) + '\n');
            }
        }
        
        // Requirements
        promptBuilder.append('\nRequirements:\n')
                     .append('- Ensure full compliance with ' + request.region + ' regulations\n')
                     .append('- Match company brand voice and tone\n')
                     .append('- Provide 3 alternative variations\n')
                     .append('- Include compliance reasoning\n');
        
        return promptBuilder.toString();
    }
    
    
    // =====================================
    // Clause Retrieval
    // =====================================
    
    private static List<String> findSimilarClauses(AdvancedClauseRequest request) {
        List<String> similarClauses = new List<String>();
        
        try {
            List<ClauseLibrary__c> existingClauses = [
                SELECT Id, Clause_Text__c, Clause_Type__c, Region__c, 
                       Industry__c, Usage_Score__c
                FROM ClauseLibrary__c 
                WHERE Clause_Type__c = :request.contractType
                  AND Region__c = :request.region
                  AND (Industry__c = :request.industry OR Industry__c = 'Universal')
                  AND Is_Active__c = true
                ORDER BY Usage_Score__c DESC, LastModifiedDate DESC
                LIMIT 5
            ];
            
            for (ClauseLibrary__c clause : existingClauses) {
                similarClauses.add(clause.Clause_Text__c);
            }
            
        } catch (Exception e) {
            System.debug('Vector search error: ' + e.getMessage());
        }
        
        return similarClauses;
    }
    @TestVisible private static Decimal toDecimal(Object o) {
        if (o==null) return null;
        if (o instanceof Decimal) return (Decimal)o;
        try { return Decimal.valueOf(String.valueOf(o)); } catch(Exception e) { return null; }
    }

    @TestVisible
private static String extractBlock(String text, String s, String e) {
    if (String.isBlank(text)) return null;

    Integer si = text.indexOf(s);
    if (si < 0) return null;

    si += s.length();
    Integer ei = text.indexOf(e, si);
    if (ei < 0) return text.substring(si).trim();

    return text.substring(si, ei).trim();
}

@TestVisible
private static List<String> extractListBlock(String text, String startMarker, String endMarker) {
    List<String> out = new List<String>();
    String block = extractBlock(text, startMarker, endMarker);

    if (String.isBlank(block)) return out;

    for (String ln : block.split('\\n')) {
        String t = ln.trim();
        if (t.startsWith('-') || t.startsWith('*') || t.startsWith('•')) {
            t = t.replaceFirst('^[-*•]\\s*', '');
        }
        if (!String.isBlank(t)) out.add(t);
    }

    return out;
}

@TestVisible
private static Decimal heuristicConfidence(AIResult r) {
    Decimal score = 50;

    if (!String.isBlank(r.generatedText)) score += 20;
    if (r.alternatives != null && r.alternatives.size() >= 2) score += 10;
    if (r.complianceNotes != null && r.complianceNotes.size() > 0) score += 10;

    return Math.min(100, score);
}

    
    // =====================================
    // AI Callout
    // =====================================
    
    public static AIResult callAdvancedAI(String systemPrompt, String userPrompt, String model, Integer timeoutMs) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:AI_Service/v1/chat/completions');
        req.setMethod('POST');
        req.setHeader('Content-Type','application/json');
        Map<String,Object> body = new Map<String,Object>{
            'model' => model,
            'messages' => new List<Object>{ new Map<String,Object>{'role'=>'system','content'=>systemPrompt}, new Map<String,Object>{'role'=>'user','content'=>userPrompt} },
            'temperature' => 0.2
        };
        req.setBody(JSON.serialize(body));
        req.setTimeout(timeoutMs==null?120000:timeoutMs);

        Http http = new Http();
        HttpResponse res = http.send(req);

        AIResult result = new AIResult();
        result.alternatives = new List<String>();
        result.complianceNotes = new List<String>();
        result.rawResponse = res.getBody();

        if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
            try {
                Map<String,Object> parsed = (Map<String,Object>)JSON.deserializeUntyped(res.getBody());
                // robust navigation: choices->[0]->message->content
                if (parsed.containsKey('choices')) {
                    List<Object> choices = (List<Object>) parsed.get('choices');
                    if (!choices.isEmpty()) {
                        Map<String,Object> first = (Map<String,Object>) choices[0];
                        if (first.containsKey('message')) {
                            Map<String,Object> message = (Map<String,Object>) first.get('message');
                            if (message.containsKey('content')) result.generatedText = (String) message.get('content');
                        } else if (first.containsKey('text')) { result.generatedText = (String) first.get('text'); }
                    }
                }
                if (parsed.containsKey('confidence')) result.confidence = toDecimal(parsed.get('confidence'));
                if (parsed.containsKey('alternatives')) result.alternatives = (List<String>)parsed.get('alternatives');
                if (parsed.containsKey('complianceNotes')) result.complianceNotes = (List<String>) parsed.get('complianceNotes');
            } catch (Exception e) {
                // fallback: try extracting structured blocks from the raw text
                result.generatedText = extractBlock(result.rawResponse,'<generatedText>','</generatedText>');
                result.alternatives = extractListBlock(result.rawResponse,'<alternatives>','</alternatives>');
                result.complianceNotes = extractListBlock(result.rawResponse,'<complianceNotes>','</complianceNotes>');
            }
            if (result.confidence == null) result.confidence = heuristicConfidence(result);
            return result;
        }
        throw new CalloutException('AI call failed: HTTP ' + res.getStatus() + ' body:' + res.getBody());
    }
     @TestVisible private static String extractBlock(String text, String startMarker, String endMarker) {
        if (String.isBlank(text)) return null;
        Integer s = text.indexOf(startMarker);
        if (s < 0) return null;
        s += startMarker.length();
        Integer e = text.indexOf(endMarker, s);
        if (e < 0) return text.substring(s).trim();
        return text.substring(s, e).trim();
    }
    @TestVisible private static List<String> extractListBlock(String text, String startMarker, String endMarker) {
        List<String> out = new List<String>();
        String block = extractBlock(text, startMarker, endMarker);
        if (String.isBlank(block)) return out;
        for (String line : block.split('\\n')) {
            String t = line.trim();
            if (t.startsWith('-') || t.startsWith('*') || t.startsWith('•')) t = t.replaceFirst('^[-*•]\\s*','');
            if (!String.isBlank(t)) out.add(t);
        }
        return out;
    }
        @TestVisible private static Decimal heuristicConfidence(AIResult r) {
        Decimal score = 50;
        if (!String.isBlank(r.generatedText)) score += 20;
        if (r.alternatives != null && r.alternatives.size() >= 2) score += 10;
        if (r.complianceNotes != null && r.complianceNotes.size() > 0) score += 10;
        return Math.min(100, score);
    }
    // =====================================
    // System Prompt Builder
    // =====================================
    
    private static String buildSystemPrompt(AdvancedClauseRequest request) {
        return 'You are an expert legal document AI assistant specializing in ' +
               request.contractType + ' contracts for ' + request.region + ' jurisdiction. ' +
               'Your expertise includes regulatory compliance, industry best practices, and ' +
               'contextual clause generation. Always provide legally sound, region-appropriate ' +
               'content with clear reasoning for compliance requirements.';
    }
    
    
    // =====================================
    // Response Parsing
    // =====================================
    
    private static AIGeneratedClause parseAIResponse(String content) {
        AIGeneratedClause result = new AIGeneratedClause();
        
        try {
            if (content.trim().startsWith('{')) {
                Map<String, Object> parsedContent = 
                    (Map<String, Object>) JSON.deserializeUntyped(content);
                
                result.generatedText        = (String) parsedContent.get('generatedClause');
                result.reasoning            = (String) parsedContent.get('reasoning');
                result.suggestedAlternatives= (List<String>) parsedContent.get('alternatives');
                result.complianceNotes      = (List<String>) parsedContent.get('complianceNotes');
                
            } else {
                result.generatedText        = extractSection(content, 'Generated Clause:', 'Reasoning:');
                result.reasoning            = extractSection(content, 'Reasoning:', 'Alternatives:');
                result.suggestedAlternatives= extractListSection(content, 'Alternatives:');
                result.complianceNotes      = extractListSection(content, 'Compliance Notes:');
            }
            
        } catch (Exception e) {
            System.debug('Response parsing error: ' + e.getMessage());
            result.generatedText = content;
        }
        
        return result;
    }
    
    
    // =====================================
    // Confidence Scoring
    // =====================================
    
    private static Decimal calculateConfidenceScore(AIGeneratedClause result) {
        Decimal score = 70.0;
        
        if (String.isNotBlank(result.reasoning)) score += 10;
        if (result.suggestedAlternatives != null && result.suggestedAlternatives.size() >= 2) score += 10;
        if (result.complianceNotes != null && result.complianceNotes.size() >= 1) score += 5;
        if (result.generatedText.length() > 100) score += 5;
        
        return Math.min(score, 100.0);
    }
    
    
    // =====================================
    // Persistence
    // =====================================
    
    private static void storeAIGeneratedResult(AIGeneratedClause result, String configId) {
        AIInsight__c insight = new AIInsight__c(
            DocumentId__c         = configId,
            Insight_Type__c       = 'ADVANCED_GENERATION',
            Insight_Content__c    = result.generatedText,
            Confidence_Score__c   = result.confidenceScore,
            AI_Reasoning__c       = result.reasoning,
            Alternative_Options__c= String.join(result.suggestedAlternatives, '; '),
            Compliance_Notes__c   = String.join(result.complianceNotes, '; '),
            Created_Date__c       = DateTime.now(),
            Is_Active__c          = true
        );
        
        insert insight;
        updateClauseUsageStats(result, configId);
    }
    
    private static void updateClauseUsageStats(AIGeneratedClause result, String configId) {
        List<ClauseUsageStats__c> existingStats = [
            SELECT Id, Usage_Count__c, Average_Confidence__c, Success_Rate__c
            FROM ClauseUsageStats__c 
            WHERE Document_Config_Id__c = :configId 
            LIMIT 1
        ];
        
        ClauseUsageStats__c stats;
        
        if (!existingStats.isEmpty()) {
            stats = existingStats[0];
            stats.Usage_Count__c = (stats.Usage_Count__c != null ? stats.Usage_Count__c : 0) + 1;
            stats.Average_Confidence__c = 
                ((stats.Average_Confidence__c * (stats.Usage_Count__c - 1)) + result.confidenceScore) 
                / stats.Usage_Count__c;
            update stats;
        } else {
            stats = new ClauseUsageStats__c(
                Document_Config_Id__c = configId,
                Usage_Count__c        = 1,
                Average_Confidence__c = result.confidenceScore,
                Success_Rate__c       = 100,
                Last_Used_Date__c     = DateTime.now()
            );
            insert stats;
        }
    }
    
    private static void createAIErrorAudit(String configId, String errorMessage) {
        AuditTrail__c errorAudit = new AuditTrail__c(
            RecordId__c      = configId,
            Action__c        = 'AI_GENERATION_ERROR',
            Status__c        = 'ERROR',
            Timestamp__c     = DateTime.now(),
            UserDetails__c   = UserInfo.getName(),
            SystemInfo__c    = 'Advanced AI Service',
            AdditionalInfo__c= errorMessage,
            Error_Code__c    = 'AI_SERVICE_ERROR'
        );
        
        insert errorAudit;
    }
    
    
    // =====================================
    // Utility Methods
    // =====================================
    
    private static String extractSection(String content, String startMarker, String endMarker) {
        Integer startIndex = content.indexOf(startMarker);
        if (startIndex == -1) return '';
        
        startIndex += startMarker.length();
        Integer endIndex = content.indexOf(endMarker, startIndex);
        if (endIndex == -1) endIndex = content.length();
        
        return content.substring(startIndex, endIndex).trim();
    }
    
    private static List<String> extractListSection(String content, String marker) {
        List<String> items = new List<String>();
        Integer startIndex = content.indexOf(marker);
        
        if (startIndex != -1) {
            startIndex += marker.length();
            String section = content.substring(startIndex);
            String[] lines = section.split('\n');
            
            for (String line : lines) {
                line = line.trim();
                if (line.startsWith('-') || line.startsWith('•') || line.startsWith('*')) {
                    items.add(line.substring(1).trim());
                } else if (String.isBlank(line) && !items.isEmpty()) {
                    break;
                }
            }
        }
        
        return items;
    }
    
    
    // =====================================
    // Document Analysis
    // =====================================
    
    public static Map<String, Object> analyzeDocumentContext(
        String documentContent, 
        String documentType
    ) {
        Map<String, Object> analysis = new Map<String, Object>();
        
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(AI_ENDPOINT + '/v1/chat/completions');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(30000);
            
            Map<String, Object> payload = new Map<String, Object>{
                'model' => 'gpt-4-turbo',
                'messages' => new List<Map<String, Object>>{
                    new Map<String, Object>{
                        'role' => 'system',
                        'content' => 'You are a legal document analysis expert. ' +
                                     'Analyze the provided document and extract key insights, risks, and recommendations.'
                    },
                    new Map<String, Object>{
                        'role' => 'user',
                        'content' => 'Analyze this ' + documentType + ' document:\n\n' + 
                                     documentContent.abbreviate(6000) +
                                     '\n\nProvide analysis in JSON format with: keyTerms, riskFactors, complianceGaps, recommendations, sentimentScore'
                    }
                },
                'temperature' => 0.2,
                'max_tokens' => 1500
            };
            
            req.setBody(JSON.serialize(payload));
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseData = 
                    (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                
                List<Object> choices = (List<Object>) responseData.get('choices');
                if (!choices.isEmpty()) {
                    Map<String, Object> choice = (Map<String, Object>) choices[0];
                    Map<String, Object> message = (Map<String, Object>) choice.get('message');
                    String analysisContent = (String) message.get('content');
                    
                    if (analysisContent.trim().startsWith('{')) {
                        analysis = (Map<String, Object>) JSON.deserializeUntyped(analysisContent);
                    } else {
                        analysis.put('keyTerms',       extractListFromText(analysisContent, 'Key Terms:'));
                        analysis.put('riskFactors',    extractListFromText(analysisContent, 'Risk Factors:'));
                        analysis.put('complianceGaps', extractListFromText(analysisContent, 'Compliance Gaps:'));
                        analysis.put('recommendations',extractListFromText(analysisContent, 'Recommendations:'));
                        analysis.put('sentimentScore', 0.7);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Document analysis error: ' + e.getMessage());
            analysis.put('error', e.getMessage());
        }
        
        return analysis;
    }
    
    private static List<String> extractListFromText(String content, String marker) {
        List<String> items = new List<String>();
        Integer startIndex = content.indexOf(marker);
        
        if (startIndex != -1) {
            startIndex += marker.length();
            String[] lines = content.substring(startIndex).split('\n');
            
            for (String line : lines) {
                line = line.trim();
                if (line.startsWith('-') || line.startsWith('•')) {
                    items.add(line.substring(1).trim());
                } else if (String.isBlank(line) && !items.isEmpty()) {
                    break;
                }
            }
        }
        
        return items;
    }
}
