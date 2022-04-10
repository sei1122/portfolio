package main

import (
	"context"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
	"os"
	"runtime"
	"time"

	secretmanager "cloud.google.com/go/secretmanager/apiv1"
	"github.com/sendgrid/sendgrid-go"
	"github.com/sendgrid/sendgrid-go/helpers/mail"
	"golang.org/x/crypto/acme/autocert"
	secretmanagerpb "google.golang.org/genproto/googleapis/cloud/secretmanager/v1"
)

func addSecretsToEnv(ctx context.Context, client *secretmanager.Client, secretName string, envName string) error {
	apikey := os.Getenv(envName)
	if apikey != "" {
		// have env var so don't process more.
		fmt.Printf("Found %s\n", envName)
		return nil
	}
	fmt.Printf("Did not find %s\n", envName)

	projectId := os.Getenv("PROJECT_ID")
	// Build the request.
	req := &secretmanagerpb.AccessSecretVersionRequest{
		Name: fmt.Sprintf("projects/%s/secrets/%s/versions/latest", projectId, secretName),
	}

	// Call the API.
	result, err := client.AccessSecretVersion(ctx, req)
	if err != nil {
		fmt.Printf("failed to access secret version: %v %s %s", err, secretName, envName)
		return fmt.Errorf("failed to access secret version: %v %s %s", err, secretName, envName)
	}

	os.Setenv(envName, string(result.Payload.Data))

	return nil
}

// GoogleRecaptchaResponse ...
type GoogleRecaptchaResponse struct {
	Success            bool     `json:"success"`
	ChallengeTimestamp string   `json:"challenge_ts"`
	Hostname           string   `json:"hostname"`
	ErrorCodes         []string `json:"error-codes"`
}

// This will handle the reCAPTCHA verification between your server to Google's server
func validateReCAPTCHA(recaptchaResponse string) (bool, error) {

	// Check this URL verification details from Google
	// https://developers.google.com/recaptcha/docs/verify
	req, err := http.PostForm("https://www.google.com/recaptcha/api/siteverify", url.Values{
		"secret":   {os.Getenv("RECAPTCHA_API_KEY")},
		"response": {recaptchaResponse},
	})
	if err != nil { // Handle error from HTTP POST to Google reCAPTCHA verify server
		return false, err
	}
	defer req.Body.Close()
	body, err := ioutil.ReadAll(req.Body) // Read the response from Google
	if err != nil {
		return false, err
	}

	var googleResponse GoogleRecaptchaResponse
	err = json.Unmarshal(body, &googleResponse) // Parse the JSON response from Google
	if err != nil {
		return false, err
	}
	return googleResponse.Success, nil
}

type contactForm struct {
	Name      string `json:"name"`
	Email     string `json:"email"`
	Subject   string `json:"subject"`
	Message   string `json:"message"`
	ReCaptcha string `json:"g-recaptcha-response"`
}

func sendHandle(rw http.ResponseWriter, req *http.Request) {
	if req.Method != "POST" {
		http.Error(rw, "not a post", 500)
		return
	}

	if err := req.ParseForm(); err != nil {
		http.Error(rw, "ParseForm failed", 500)
		return
	}
	var c contactForm

	c.Name = req.FormValue("name")
	c.Email = req.FormValue("email")
	c.Subject = req.FormValue("subject")
	c.Message = req.FormValue("message")
	c.ReCaptcha = req.FormValue("g-recaptcha-response")

	result, err := validateReCAPTCHA(c.ReCaptcha)
	if err != nil || !result {
		errstr := fmt.Sprintf("error = %v result = %v", err, result)
		http.Error(rw, "please hit I am not robot button\n or = "+errstr, 500)
		return
	}

	// this function returns the present time
	now := time.Now()
	// try to use PST
	location, err := time.LoadLocation("America/Los_Angeles")
	if err == nil {
		now = now.In(location)
	}

	datestr := fmt.Sprintf(now.Format("2006-01-02 at 15:04:05"))

	msg := ""
	msg += fmt.Sprintf("Message from Portfolio site.  Submitted on %s.\n\n", datestr)

	prettyJSON, err := json.MarshalIndent(c, "", "    ")
	if err != nil {
		errstr := fmt.Sprintf("%v", err)
		http.Error(rw, "Failed to generate json "+errstr, 500)
	}
	msg += string(prettyJSON)

	from := mail.NewEmail("FormMailer", "seikoigi@seikoigi.com")
	subject := "Message from Seiko's Website"
	to := mail.NewEmail("Seiko Igi", "seikoigi@gmail.com")

	message := mail.NewSingleEmail(from, subject, to, msg, msg)
	client := sendgrid.NewSendClient(os.Getenv("SENDGRID_API_KEY"))
	response, err := client.Send(message)
	if err != nil {
		log.Println(err)
	} else {
		fmt.Println(response.StatusCode)
		fmt.Println(response.Body)
		fmt.Println(response.Headers)
	}

	http.Redirect(rw, req, "thanks.html", http.StatusSeeOther)
}

func AddSecretToEnv() {
	// Create the client.
	// this will fail on windows
	// so manually add these envioment
	// vars to your envioment
	ctx := context.Background()
	client, err := secretmanager.NewClient(ctx)
	if err != nil {
		log.Println(fmt.Sprintf("failed to create secretmanager client: %v", err))
		return
	}
	log.Println(fmt.Sprintf("Adding secrets"))

	addSecretsToEnv(ctx, client, "SENDGRID_API_KEY", "SENDGRID_API_KEY")
	addSecretsToEnv(ctx, client, "RECAPTCHA_API_KEY", "RECAPTCHA_API_KEY")
}

func main() {

	isWin := false
	if runtime.GOOS == "windows" {
		isWin = true
		// Disable log prefixes such as the default timestamp.
		// Prefix text prevents the message from being parsed as JSON.
		// A timestamp is added when shipping logs to Cloud Logging.
		log.SetFlags(0)
	}

	AddSecretToEnv()

	port := os.Getenv("PORT")
	if port == "" {
		if isWin {
			port = "8080"
		} else {
			port = "80"
		}
		log.Printf("Defaulting to port %s", port)
	}

	http.Handle("/", http.FileServer(http.Dir("web/")))
	http.HandleFunc("/submit", sendHandle)

	if isWin {
		log.Printf("Listening on port with http %s", port)
		if err := http.ListenAndServe(":"+port, nil); err != nil {
			log.Fatal(err)
		}
	} else {
		certManager := autocert.Manager{
			Prompt:     autocert.AcceptTOS,
			HostPolicy: autocert.HostWhitelist("seikoigi.com", "www.seikoigi.com"), //Your domain here
			Cache:      autocert.DirCache("certs"),                                 //Folder for storing certificates
		}
		server := &http.Server{
			Addr: ":https",
			TLSConfig: &tls.Config{
				GetCertificate: certManager.GetCertificate,
			},
		}

		go func() {
			log.Printf("Listening on port %s http and 443 for https", port)
			if err := http.ListenAndServe(":"+port, certManager.HTTPHandler(nil)); err != nil {
				log.Fatal(err)
			}
		}()

		log.Fatal(server.ListenAndServeTLS("", "")) //Key and cert are coming from Let's Encrypt
	}

}
