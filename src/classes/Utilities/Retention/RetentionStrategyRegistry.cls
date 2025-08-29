/**
 * @description Registry class that manages retention strategies using the factory pattern.
 * Provides centralized strategy selection and registration for different object types.
 * 
 * @author Valerii Artemenko
 * @version 1.0
 * @since 2025-01-28
 */
public with sharing class RetentionStrategyRegistry {
    
    private static Map<String, RetentionStrategy> strategyMap;
    
    static {
        initializeStrategies();
    }
    
    /**
     * @description Gets the appropriate retention strategy for the specified object type
     * @param objectApiName API name of the object
     * @return RetentionStrategy The strategy to use for the object type
     */
    public static RetentionStrategy getStrategy(String objectApiName) {
        if (String.isBlank(objectApiName)) {
            return getDefaultStrategy();
        }
        
        String key = objectApiName.toLowerCase();
        
        if (strategyMap.containsKey(key)) {
            return strategyMap.get(key);
        }
        
        // Return default strategy for unsupported object types
        return getDefaultStrategy();
    }
    
    /**
     * @description Gets the appropriate strategy for a retention configuration
     * @param retentionConfig Retention configuration
     * @return RetentionStrategy The strategy to use
     */
    public static RetentionStrategy getStrategy(Retention__c retentionConfig) {
        if (retentionConfig == null || String.isBlank(retentionConfig.TargetObject__c)) {
            return getDefaultStrategy();
        }
        
        return getStrategy(retentionConfig.TargetObject__c);
    }
    
    /**
     * @description Returns the default retention strategy
     * @return RetentionStrategy Default strategy instance
     */
    public static RetentionStrategy getDefaultStrategy() {
        return new DefaultRetentionStrategy();
    }
    
    /**
     * @description Registers a custom strategy for an object type
     * @param objectApiName API name of the object
     * @param strategy Strategy instance to register
     */
    public static void registerStrategy(String objectApiName, RetentionStrategy strategy) {
        if (String.isNotBlank(objectApiName) && strategy != null) {
            strategyMap.put(objectApiName.toLowerCase(), strategy);
        }
    }
    
    /**
     * @description Initializes the strategy registry with default mappings
     */
    private static void initializeStrategies() {
        strategyMap = new Map<String, RetentionStrategy>();
        
        // Register default strategy for common objects
        // Future: Register specialized strategies for Files, Attachments, etc.
        DefaultRetentionStrategy defaultStrategy = new DefaultRetentionStrategy();
        
        // All objects use default strategy for now
        // This can be extended to support specialized strategies
    }
    
    /**
     * @description Validates that a strategy exists for the given object type
     * @param objectApiName API name of the object
     * @return Boolean True if a strategy is available
     */
    public static Boolean hasStrategy(String objectApiName) {
        if (String.isBlank(objectApiName)) {
            return true; // Default strategy is always available
        }
        
        RetentionStrategy strategy = getStrategy(objectApiName);
        return strategy != null && strategy.supportsObjectType(objectApiName);
    }
}