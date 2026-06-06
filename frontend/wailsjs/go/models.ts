export namespace vibecoding {
	
	export class ApprovalConfig {
	    bashWhitelist?: string[];
	    bashBlacklist?: string[];
	    confirmBeforeWrite?: boolean;
	
	    static createFrom(source: any = {}) {
	        return new ApprovalConfig(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.bashWhitelist = source["bashWhitelist"];
	        this.bashBlacklist = source["bashBlacklist"];
	        this.confirmBeforeWrite = source["confirmBeforeWrite"];
	    }
	}
	export class CompactionConfig {
	    enabled: boolean;
	    reserveTokens: number;
	    keepRecentTokens: number;
	
	    static createFrom(source: any = {}) {
	        return new CompactionConfig(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.enabled = source["enabled"];
	        this.reserveTokens = source["reserveTokens"];
	        this.keepRecentTokens = source["keepRecentTokens"];
	    }
	}
	export class ContextFilesConfig {
	    enabled: boolean;
	    extraFiles?: string[];
	
	    static createFrom(source: any = {}) {
	        return new ContextFilesConfig(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.enabled = source["enabled"];
	        this.extraFiles = source["extraFiles"];
	    }
	}
	export class CostConfig {
	    input: number;
	    output: number;
	    cacheRead?: number;
	    cacheWrite?: number;
	
	    static createFrom(source: any = {}) {
	        return new CostConfig(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.input = source["input"];
	        this.output = source["output"];
	        this.cacheRead = source["cacheRead"];
	        this.cacheWrite = source["cacheWrite"];
	    }
	}
	export class ModelCompat {
	    thinkingFormat?: string;
	    requiresReasoningContentOnAssistant?: boolean;
	    requiresReasoningContentOnAssistantMessages?: boolean;
	    forceAdaptiveThinking?: boolean;
	    supportsDeveloperRole?: boolean;
	    supportsStore?: boolean;
	    supportsReasoningEffort?: boolean;
	    supportsStrictMode?: boolean;
	    maxTokensField?: string;
	    supportsCacheControlOnTools?: boolean;
	    supportsLongCacheRetention?: boolean;
	    supportsPromptCacheKey?: boolean;
	    supportsReasoningSummary?: boolean;
	    sendSessionAffinityHeaders?: boolean;
	    supportsEagerToolInputStreaming?: boolean;
	
	    static createFrom(source: any = {}) {
	        return new ModelCompat(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.thinkingFormat = source["thinkingFormat"];
	        this.requiresReasoningContentOnAssistant = source["requiresReasoningContentOnAssistant"];
	        this.requiresReasoningContentOnAssistantMessages = source["requiresReasoningContentOnAssistantMessages"];
	        this.forceAdaptiveThinking = source["forceAdaptiveThinking"];
	        this.supportsDeveloperRole = source["supportsDeveloperRole"];
	        this.supportsStore = source["supportsStore"];
	        this.supportsReasoningEffort = source["supportsReasoningEffort"];
	        this.supportsStrictMode = source["supportsStrictMode"];
	        this.maxTokensField = source["maxTokensField"];
	        this.supportsCacheControlOnTools = source["supportsCacheControlOnTools"];
	        this.supportsLongCacheRetention = source["supportsLongCacheRetention"];
	        this.supportsPromptCacheKey = source["supportsPromptCacheKey"];
	        this.supportsReasoningSummary = source["supportsReasoningSummary"];
	        this.sendSessionAffinityHeaders = source["sendSessionAffinityHeaders"];
	        this.supportsEagerToolInputStreaming = source["supportsEagerToolInputStreaming"];
	    }
	}
	export class ModelConfig {
	    id: string;
	    name: string;
	    reasoning?: boolean;
	    contextWindow?: number;
	    maxTokens?: number;
	    temperature?: number;
	    top_p?: number;
	    cost?: CostConfig;
	    input?: string[];
	    compat?: ModelCompat;
	
	    static createFrom(source: any = {}) {
	        return new ModelConfig(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.id = source["id"];
	        this.name = source["name"];
	        this.reasoning = source["reasoning"];
	        this.contextWindow = source["contextWindow"];
	        this.maxTokens = source["maxTokens"];
	        this.temperature = source["temperature"];
	        this.top_p = source["top_p"];
	        this.cost = this.convertValues(source["cost"], CostConfig);
	        this.input = source["input"];
	        this.compat = this.convertValues(source["compat"], ModelCompat);
	    }
	
		convertValues(a: any, classs: any, asMap: boolean = false): any {
		    if (!a) {
		        return a;
		    }
		    if (a.slice && a.map) {
		        return (a as any[]).map(elem => this.convertValues(elem, classs));
		    } else if ("object" === typeof a) {
		        if (asMap) {
		            for (const key of Object.keys(a)) {
		                a[key] = new classs(a[key]);
		            }
		            return a;
		        }
		        return new classs(a);
		    }
		    return a;
		}
	}
	export class ProviderConfig {
	    apiKey: string;
	    baseUrl: string;
	    httpProxy?: string;
	    api: string;
	    thinkingFormat?: string;
	    cacheControl?: boolean;
	    models: ModelConfig[];
	
	    static createFrom(source: any = {}) {
	        return new ProviderConfig(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.apiKey = source["apiKey"];
	        this.baseUrl = source["baseUrl"];
	        this.httpProxy = source["httpProxy"];
	        this.api = source["api"];
	        this.thinkingFormat = source["thinkingFormat"];
	        this.cacheControl = source["cacheControl"];
	        this.models = this.convertValues(source["models"], ModelConfig);
	    }
	
		convertValues(a: any, classs: any, asMap: boolean = false): any {
		    if (!a) {
		        return a;
		    }
		    if (a.slice && a.map) {
		        return (a as any[]).map(elem => this.convertValues(elem, classs));
		    } else if ("object" === typeof a) {
		        if (asMap) {
		            for (const key of Object.keys(a)) {
		                a[key] = new classs(a[key]);
		            }
		            return a;
		        }
		        return new classs(a);
		    }
		    return a;
		}
	}
	export class RetryConfig {
	    enabled: boolean;
	    maxRetries: number;
	    baseDelayMs: number;
	
	    static createFrom(source: any = {}) {
	        return new RetryConfig(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.enabled = source["enabled"];
	        this.maxRetries = source["maxRetries"];
	        this.baseDelayMs = source["baseDelayMs"];
	    }
	}
	export class SandboxConfig {
	    enabled: boolean;
	    level: string;
	    bwrapPath?: string;
	    allowNetwork: boolean;
	    allowedRead?: string[];
	    allowedWrite?: string[];
	    deniedPaths?: string[];
	    passEnv?: string[];
	    tmpSize?: string;
	
	    static createFrom(source: any = {}) {
	        return new SandboxConfig(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.enabled = source["enabled"];
	        this.level = source["level"];
	        this.bwrapPath = source["bwrapPath"];
	        this.allowNetwork = source["allowNetwork"];
	        this.allowedRead = source["allowedRead"];
	        this.allowedWrite = source["allowedWrite"];
	        this.deniedPaths = source["deniedPaths"];
	        this.passEnv = source["passEnv"];
	        this.tmpSize = source["tmpSize"];
	    }
	}
	export class SessionConfig {
	    cwd: string;
	    provider?: string;
	    model?: string;
	    mode?: string;
	    thinking?: string;
	
	    static createFrom(source: any = {}) {
	        return new SessionConfig(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.cwd = source["cwd"];
	        this.provider = source["provider"];
	        this.model = source["model"];
	        this.mode = source["mode"];
	        this.thinking = source["thinking"];
	    }
	}
	export class WebSearchSettings {
	    enabled?: boolean;
	    provider?: string;
	    providerType?: string;
	    model?: string;
	
	    static createFrom(source: any = {}) {
	        return new WebSearchSettings(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.enabled = source["enabled"];
	        this.provider = source["provider"];
	        this.providerType = source["providerType"];
	        this.model = source["model"];
	    }
	}
	export class VibeCodingSettings {
	    providers: Record<string, ProviderConfig>;
	    defaultProvider: string;
	    defaultModel: string;
	    defaultThinkingLevel: string;
	    defaultMode: string;
	    enablePlanTool?: boolean;
	    webSearch: WebSearchSettings;
	    maxContextTokens?: number;
	    maxOutputTokens?: number;
	    contextFiles?: ContextFilesConfig;
	    skillsDir?: string;
	    compaction?: CompactionConfig;
	    sandbox?: SandboxConfig;
	    sessionDir?: string;
	    shellPath?: string;
	    shellCommandPrefix?: string;
	    theme?: string;
	    retry?: RetryConfig;
	    approval?: ApprovalConfig;
	
	    static createFrom(source: any = {}) {
	        return new VibeCodingSettings(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.providers = this.convertValues(source["providers"], ProviderConfig, true);
	        this.defaultProvider = source["defaultProvider"];
	        this.defaultModel = source["defaultModel"];
	        this.defaultThinkingLevel = source["defaultThinkingLevel"];
	        this.defaultMode = source["defaultMode"];
	        this.enablePlanTool = source["enablePlanTool"];
	        this.webSearch = this.convertValues(source["webSearch"], WebSearchSettings);
	        this.maxContextTokens = source["maxContextTokens"];
	        this.maxOutputTokens = source["maxOutputTokens"];
	        this.contextFiles = this.convertValues(source["contextFiles"], ContextFilesConfig);
	        this.skillsDir = source["skillsDir"];
	        this.compaction = this.convertValues(source["compaction"], CompactionConfig);
	        this.sandbox = this.convertValues(source["sandbox"], SandboxConfig);
	        this.sessionDir = source["sessionDir"];
	        this.shellPath = source["shellPath"];
	        this.shellCommandPrefix = source["shellCommandPrefix"];
	        this.theme = source["theme"];
	        this.retry = this.convertValues(source["retry"], RetryConfig);
	        this.approval = this.convertValues(source["approval"], ApprovalConfig);
	    }
	
		convertValues(a: any, classs: any, asMap: boolean = false): any {
		    if (!a) {
		        return a;
		    }
		    if (a.slice && a.map) {
		        return (a as any[]).map(elem => this.convertValues(elem, classs));
		    } else if ("object" === typeof a) {
		        if (asMap) {
		            for (const key of Object.keys(a)) {
		                a[key] = new classs(a[key]);
		            }
		            return a;
		        }
		        return new classs(a);
		    }
		    return a;
		}
	}

}

