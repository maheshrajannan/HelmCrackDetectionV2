Pointing a Domain to a New IP in Google Cloud DNS [video_url](https://drive.google.com/file/d/1r4kNKKGeuwzQSgonVLGuGPev1a-HaChS/view?usp=sharing)

If you're using Google Cloud DNS to manage your domain and need to update it to point to a new IP, follow these steps:
1. Identify Your DNS Zone

    Go to the Google Cloud Console: https://console.cloud.google.com/
    Navigate to "Network Services" > "Cloud DNS".
    Locate the DNS zone associated with your domain.
![DNSgcloud](/docScreenshots/DNSzoneGcloud.png)
Now you will get domain namservers inside created zone like below image,
![DNS-Nameservers](/docScreenshots/DNS-Nameservers.png)
So you need to update this nameservers in your register domain host, in my case I've taken this domain from hostinger, so add these nameservers in hostinger like below image
![HostingerNameservers](/docScreenshots/HostingerNameservers.png)
Now wait untill your domains nameservers properly bind with gcloud DNS nameservers OR not
Let see in this website,
![DNScheck](/docScreenshots/DNScheck.png)
so now it's connected and we can use this domain to bind the IP from gcloud zone.
2. Update the A Record

    Click on the DNS zone for your domain.
    Look for an A record (Type: A) that maps your domain (e.g., example.com) to an IP address.
    Click "Edit" for that record.
    Replace the old IP address with the new IP address.
    Click "Create" to save changes.
![IP-Binding](/docScreenshots/BindingIP.png)

3. (Optional) Update Subdomains

    If you have subdomains (e.g., www.example.com), repeat the above steps for their respective A records.
    If using a CNAME record (e.g., www.example.com → example.com), no changes are needed unless you're altering the root domain.

4. Verify DNS Changes

After updating, verify the changes:

    Run this command in the terminal:

nslookup example.com

or

    dig example.com

    Check propagation using a global DNS checker: https://www.whatsmydns.net/

5. (Optional) Reduce DNS TTL for Faster Updates

    If you anticipate frequent IP changes, reduce the Time-To-Live (TTL) to a lower value (e.g., 300 seconds).
    This speeds up propagation for future changes.

6. Allow Time for Propagation

    DNS updates can take anywhere from a few minutes to up to 48 hours globally, depending on your TTL settings.

Your domain should now resolve to the new IP address successfully.