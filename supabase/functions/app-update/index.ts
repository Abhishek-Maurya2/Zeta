// Supabase Edge Function: app-update
// Proxies releases and binary downloads for a private GitHub repository,
// keeping your GitHub Personal Access Token (PAT) completely hidden from client binaries.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const owner = url.searchParams.get("owner") || "Abhishek-Maurya2";
    const repo = url.searchParams.get("repo") || "Zeta";
    const assetId = url.searchParams.get("asset_id");

    // Secret stored in Supabase Project Settings -> Edge Functions -> Secrets
    const githubToken = Deno.env.get("GITHUB_RELEASE_TOKEN") || Deno.env.get("GITHUB_TOKEN");

    if (!githubToken) {
      return new Response(
        JSON.stringify({
          error: "GITHUB_RELEASE_TOKEN is not configured in Supabase environment secrets.",
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // 1. Download asset proxy mode
    if (assetId) {
      const assetUrl = `https://api.github.com/repos/${owner}/${repo}/releases/assets/${assetId}`;
      const assetRes = await fetch(assetUrl, {
        headers: {
          Authorization: `Bearer ${githubToken}`,
          Accept: "application/octet-stream",
        },
        redirect: "manual", // Capture 302 redirect location
      });

      const redirectLocation = assetRes.headers.get("location");
      if (redirectLocation) {
        // Redirect client to Amazon S3 pre-signed URL directly
        return Response.redirect(redirectLocation, 302);
      } else {
        // Stream binary directly
        return new Response(assetRes.body, {
          status: assetRes.status,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/octet-stream",
          },
        });
      }
    }

    // 2. Check latest release metadata mode
    const releaseUrl = `https://api.github.com/repos/${owner}/${repo}/releases/latest`;
    const releaseRes = await fetch(releaseUrl, {
      headers: {
        Authorization: `Bearer ${githubToken}`,
        Accept: "application/vnd.github.v3+json",
        "User-Agent": "Zeta-App-Updater",
      },
    });

    if (!releaseRes.ok) {
      const errText = await releaseRes.text();
      return new Response(
        JSON.stringify({
          error: `GitHub API error: ${releaseRes.statusText}`,
          details: errText,
        }),
        {
          status: releaseRes.status,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const releaseData = await releaseRes.json();

    // Sanitize release payload to return to app
    const sanitized = {
      tag_name: releaseData.tag_name,
      name: releaseData.name,
      body: releaseData.body,
      published_at: releaseData.published_at,
      assets: (releaseData.assets || []).map((a: any) => ({
        id: a.id,
        name: a.name,
        size: a.size,
        browser_download_url: a.browser_download_url,
        url: a.url,
      })),
    };

    return new Response(JSON.stringify(sanitized), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
