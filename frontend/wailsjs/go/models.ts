export namespace vibecoding {
	
	export class ModelConfig {
	    id: string;
	    name: string;
	    contextWindow: number;
	    maxTokens: number;
	
	    static createFrom(source: any = {}) {
	        return new ModelConfig(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.id = source["id"];
	        this.name = source["name"];
	        this.contextWindow = source["contextWindow"];
	        this.maxTokens = source["maxTokens"];
	    }
	}
	export class ProviderConfig {
	    apiKey: string;
	    baseUrl: string;
	    api: string;
	    models: ModelConfig[];
	
	    static createFrom(source: any = {}) {
	        return new ProviderConfig(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.apiKey = source["apiKey"];
	        this.baseUrl = source["baseUrl"];
	        this.api = source["api"];
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
	export class VibeCodingSettings {
	    providers: Record<string, ProviderConfig>;
	    defaultProvider: string;
	    defaultModel: string;
	    defaultThinkingLevel: string;
	    defaultMode: string;
	
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

