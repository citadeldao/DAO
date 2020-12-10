let totalSupply = 1_000_000_000;

let emissionPool = 600_000_000;
let emission = 0;

let circulatingSupply = 100_000_000;

for(let i = 0; i < 23; i++){
    let em = 0;
    if(i > 0){
        em = countEmission();
        emissionPool -= em;
        emission += em;
        //console.log(emission, em);
        circulatingSupply += em;
    }
    if(i === 1) circulatingSupply += 15_000_000 + 10_000_000;
    if(i === 2) circulatingSupply += 22_500_000 + 15_000_000;
    if(i === 3) circulatingSupply += 45_000_000 + 30_000_000;
    if(i === 4) circulatingSupply += 67_500_000 + 45_000_000;
    if(i < 5) circulatingSupply += 10_000_000; // FF
    console.log('Year', i);
    console.log('circulatingSupply', format(circulatingSupply));
    console.log('emission', format(em));
    //console.log('');
}

function countEmission(){
    if(emissionPool < circulatingSupply * 0.02){
        return emissionPool;
    }else{
        return Math.round(Math.max(emissionPool/10, circulatingSupply * 0.02));
    }
}

function format(num){
    return new Intl.NumberFormat('de-DE').format(num);
}
