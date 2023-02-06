#!/bin/bash

#Vladimir Gutierrez Bash ATM Program 1.0
#Ability to sign up or create an account, deposit or withdraw to/from account balance, change password, and view account information.

#User Introduction
function usrIntro(){
    echo "-----------------------------------";
    echo "Thank you for using Gutierrez Bank!";
    echo "-----------------------------------";
    sleep 1;

    read -p "Would you like to login (L) or signup (S): " usrLoginOrSignup;

    if [[ $usrLoginOrSignup == [Ll] ]]; then
        usrLogin;
    elif [[ $usrLoginOrSignup = [Ss] ]]; then
        usrSignup;
    else
        echo "Invalid input. Please try again.";
        sleep 1;
        usrIntro;
    fi
}

#Checks to see if username and password is in database
checkDB(){
    name="'$1'";
    usrNameCheck=$(sqlite3 notUsrInfo.db  "select usrName from usrs where usrName=$name");
    usrPassCheck=$(sqlite3 notUsrInfo.db  "select usrPass from usrs where usrName=$name");
    if [[ $usrNameCheck == $1 ]]; then
        if [[ $usrPassCheck == $2 ]]; then
            echo "1";
        else
            echo "0";
        fi
    else
        echo "0";
    fi
}

#Get User Info
getUsrInfo(){
    name="'$1'";
    usrInfo=$(sqlite3 notUsrInfo.db  "select * from usrs where usrName=$name");
    IFS="|" read -r usrName usrPass cardNum cvcNum expiryDate usrBal <<< "'$usrInfo'";
    usrName="$(echo $usrName | tr -d \')";
    usrBal="$(echo $usrBal | tr -d \')";
    echo $usrName $usrPass $cardNum $cvcNum $expiryDate $usrBal;
}

#User Login
function usrLogin(){
    echo ; 
    read -p "Enter Username: " usrName;
    read -p "Enter Password: " usrPass;

    loginResult=$(checkDB "$usrName" "$usrPass");

    if [[ $loginResult == 1 ]]; then
        usrInfo=$(getUsrInfo "$usrName");
        usrMenu $usrInfo;
    else
        echo "Invalid credentails. Please try again.";
        unset usrName usrPass usrInfo;
        usrLogin;
    fi
}

#User Signup
function usrSignup(){
    echo ;
    read -p "Enter Username: " usrName;
    read -p "Enter Password: " usrPass;

    createAccount $usrName $usrPass;
}

#Generates new card #'s
function numberGenerator(){
    newNums= ;
    for ((x=1; x<=$1; x++))
    do
        number=$RANDOM
        let number%=10
        newNums+=$number
    done
    echo ${newNums};
}

#Generates a new expiration date
function expiryGenerator(){
    newDate= ;

    let number=$(( ( $RANDOM % 12 )  + 1 ));
    if [[ $number -lt 10 ]] 
        then
            number="0$number";
        fi
    newDate+=$number;

    newDate+="/";

    let number=$(( ( $RANDOM % 4 )  + 24 ));
    newDate+=$number;

    echo ${newDate};
}

#Creates a new Acc and adds to DB
createAccount(){
    usrName=$1;
    usrPass=$2;
    cardNum=$(numberGenerator 15);
    cvcNum=$(numberGenerator 3); 
    expiryDate=$(expiryGenerator);
    usrBal=0;

    $(sqlite3 notUsrInfo.db  "insert into usrs values('$usrName', '$usrPass', '$cardNum', '$cvcNum', '$expiryDate', $usrBal)");
    echo "Account Created! Redirecting to Login...";
    sleep 2;
    usrLogin;
}

#Main Menu
function usrMenu(){
    echo ;
    echo "Welcome, $1";
    echo ;

    usrLine="$1 $2 $3 $4 $5 $6";

    read -t 1 -n 10000 discard;
    PS3="Enter your choice: ";
    options=("Check Balance" "Deposit" "Withdraw" "Request a new Debit Card" "Change Password" "View Account Information" "Quit");
    select usrChoice in "${options[@]}"
    do
        case $usrChoice in
            "Check Balance") echo ; usrBal=$(sqlite3 notUsrInfo.db  "select usrBal from usrs where usrName='$1'") ; echo "Account Balance: \$$usrBal"; echo ;;
            "Deposit") echo ; read -p "Enter deposit amount: $" depositAmount; echo ; read -t 1 -n 10000 discard ; usrBal=$(sqlite3 notUsrInfo.db  "select usrBal from usrs where usrName='$1'") ; updatedBal=$(expr $usrBal + $depositAmount) ; echo "Deposit Successful. Updating Balance." ; $(sqlite3 notUsrInfo.db  "update usrs set usrBal = $updatedBal where usrName='$1'") ; sleep 1 ; echo "Your account balance is now: \$$updatedBal"; echo ;;
            "Withdraw") echo ; read -p "Enter withdrawal amount: $" withdrawAmount; echo ; read -t 1 -n 10000 discard ; usrBal=$(sqlite3 notUsrInfo.db  "select usrBal from usrs where usrName='$1'") ; updatedBal=$(expr $usrBal - $withdrawAmount) ; echo "Withdrawal Successful. Updating Balance." ; $(sqlite3 notUsrInfo.db  "update usrs set usrBal = $updatedBal where usrName='$1'") ; sleep 1 ; echo "Your account balance is now: \$$updatedBal"; echo ;;
            "Request a new Debit Card") echo ; echo "Generating new card information..." ; echo ; sleep 3; newCardNum="'$(numberGenerator 15)'"; newCVCNum="'$(numberGenerator 3)'" ; newExpiryDate="'$(expiryGenerator)'" ; $(sqlite3 notUsrInfo.db  "update usrs set cardNum=$newCardNum, cvcNum=$newCVCNum, expiryDate=$newExpiryDate where usrName='$1'") ; echo "New Card information updated successfully.";;
            "Change Password") echo; read -p "Enter new password: " newPass; read -t 1 -n 10000 discard; $(sqlite3 notUsrInfo.db  "update usrs set usrPass = '$newPass' where usrName='$1'") ; sleep 1; echo "Password successfully updated.";;
            "View Account Information") echo ; echo "Username: $1"; usrPass=$(sqlite3 notUsrInfo.db  "select usrPass from usrs where usrName='$1'") ; cardNum=$(sqlite3 notUsrInfo.db  "select cardNum from usrs where usrName='$1'") ; cvcNum=$(sqlite3 notUsrInfo.db  "select cvcNum from usrs where usrName='$1'") ; expiryDate=$(sqlite3 notUsrInfo.db  "select expiryDate from usrs where usrName='$1'") ; echo "Password: $usrPass"; echo "Card Number: $cardNum"; echo "CVC Number: $cvcNum"; echo "Expiry Date: $expiryDate"; echo ;;
            "Quit") exit;;
            *) echo "Invalid option $REPLY" ; echo ;;
        esac
    done < /dev/tty;

}

usrIntro;
