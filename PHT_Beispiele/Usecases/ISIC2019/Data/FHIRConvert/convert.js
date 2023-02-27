// Install csv-parser and uuid
try {

    const npm = require('npm');
    npm.load(function (err) {

        // install module
        npm.commands.install(['csv-parser'], function (er, data) {
            console.log(er)
        });

        npm.commands.install(['uuid'], function (er, data) {
            console.log(er)
        });

        npm.on('log', function (message) {
            // log installation progress
            console.log(message);
        });
    });

} catch (error) {
    console.log(error)
}

const fs = require('fs');
const csv = require('csv-parser');
const uuidv4 = require('uuid').v4;

const BATCH_SIZE = process.argv[2] || 500;
let MINIO_BASE_URL = process.argv[3] || "http://menzel.informatik.rwth-aachen.de:9000/isic/";

MINIO_BASE_URL = MINIO_BASE_URL[MINIO_BASE_URL.length - 1] === "/" ? MINIO_BASE_URL : MINIO_BASE_URL + "/";

inputPath = './input/'
outputPath = './output/'

// *** TRANSACTION-0 ***
let imagingStudy_resourceType_model = {
    "entry": [
        {
            "fullUrl": uuidv4(),
            "request": {
                "method": "PUT",
                "url": "ImagingStudy/isic"
            },
            "resource": {
                "id": "isic",
                "name": "ISIC",
                "resourceType": "ImagingStudy"
            }
        }
    ],
    "id": uuidv4(),
    "resourceType": "Bundle",
    "type": "transaction"
};

// Checking output directory
if (!fs.existsSync(outputPath)) {
    fs.mkdirSync(outputPath);
}

fs.writeFileSync(`${outputPath}/transaction-0.json`, JSON.stringify(imagingStudy_resourceType_model));
// *** TRANSACTION-0 ***

function getPatientModel(patient) {

    let id = patient.image.split("_")[1];
    let birthDate = `${new Date().getFullYear() - patient.age_approx}-07-01`
    let gender = patient.sex || "unknown";

    let model = {
        "fullUrl": uuidv4(),
        "request": {
            "method": "PUT",
            "url": `Patient/${id}`
        },
        "resource": {
            "gender": gender,
            "id": id,
            "meta": {
                "profile": [
                    "https://www.medizininformatik-initiative.de/fhir/core/StructureDefinition/Patient"
                ]
            },
            "resourceType": "Patient"
        }
    };

    if (patient.age_approx) {
        model.resource.birthDate = birthDate;
    }

    return model;
}

function getMediaModel(patient) {

    let id = patient.image.split("_")[1];
    let bodySite = patient.anatom_site_general;
    let reasonCode = patient.lesion_id;
    let createdDateTime = "2020-07-01";
    let url = `${MINIO_BASE_URL}${id}.jpg`

    let model = {
        "fullUrl": uuidv4(),
        "request": {
            "method": "PUT",
            "url": `Media/${id}-isic-image`
        },
        "resource": {
            "id": `${id}-isic-image`,
            "createdDateTime": createdDateTime,
            "resourceType": "Media",
            "status": "completed",
            "subject": {
                "reference": `Patient/${id}`
            },
            "encounter": {
                "reference": "ImagingStudy/isic"
            },
            "content": {
                "contentType": "image/jpeg",
                "url": url
            }
        }
    }

    if (bodySite) {
        model.resource.bodySite = {
            "text": bodySite
        };
    }

    if (reasonCode) {
        model.resource.reasonCode = [{
            "text": reasonCode
        }];
    }

    if (groundTruth[id]) {
        model.resource.note = [{
            "text": groundTruth[id]
        }]
    }

    return model;
}

function getTransactionModel() {
    return {
        "entry": [],
        "id": uuidv4(),
        "resourceType": "Bundle",
        "type": "transaction"
    }
}

function readMetaDataFiles() {
    let counter = 0;
    let transaction = getTransactionModel();

    fs.readdir(inputPath, (err, fileNames) => {
        fileNames.forEach(fileName => {

            if (fileName.indexOf("Metadata") < 0)
                return;

            console.log(fileName);
            let filePath = inputPath + fileName;


            fs.createReadStream(filePath)
                .pipe(csv())
                .on('data', function (row) {

                    transaction.entry.push(getPatientModel(row));
                    transaction.entry.push(getMediaModel(row));
                    counter++;

                    if (counter % BATCH_SIZE === 0) {

                        fs.writeFileSync(`${outputPath}/transaction-${counter}.json`, JSON.stringify(transaction));
                        transaction = getTransactionModel();
                    }

                })
                .on('end', function () {

                    if (counter % BATCH_SIZE !== 0) {

                        fs.writeFileSync(`${outputPath}/transaction-${Math.ceil(counter / BATCH_SIZE) * BATCH_SIZE}.json`, JSON.stringify(transaction));
                        transaction = getTransactionModel();
                    }

                    console.log(`${fileName} successfully processed`);
                });

        });
    });

}

function readGroundTruthFile() {
    return new Promise((resolve, reject) => {

        let readStream = fs.createReadStream("./input/ISIC_2019_Training_GroundTruth.csv")
            .pipe(csv())
            .on('data', function (row) {

                var note = "";
                let id = row.image.split("_")[1];
                Object.keys(row).forEach(key => {
                    if (row[key] == 1) {
                        note += `${key}`;
                        return;
                    }
                });
                groundTruth[id] = note;

            })
            .on('end', function () {

                readStream.destroy();
                console.log('ISIC_2019_Training_GroundTruth file successfully processed');
                resolve();
            })
            .on('error', (reject) => {
                console.log("error");
                reject();
            });
    })

}

groundTruth = {};
readGroundTruthFile().then(() => {
    readMetaDataFiles();
});
